import cocotb, random
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, ReadOnly
from cocotb.queue import Queue

### TESTCASES
@cocotb.test() # decorates coroutine function
async def test_hello_world(dut):
    cocotb.log.info("Yooo")

@cocotb.test()
async def single_loopback_test(dut):
    #TERMINOLOGY
    """
    Scoreboard: checks if the output of the module matches it's expected value
    Word/Packet/byte: one full UART transmission, set in parameters to be 8 bits (start, parity, and stop bits increase it to 9-12)
    """
    #PSUEDO-CODE
    """
    clock init

    define scoreboard
        -variables to store pass/fail counts
        -FIFO queue that progresses with each sent word
            -the first word added to it is also the first word to be removed
        -On RX output update: Compare the word taken out of the queue to what is received by RX
            -match: add a count to pass
            -mismatch: add a count to fail
    initial
        set init values for outputs
        hold reset high for a bit

        Random packet gen for loop (i >= 100)
            -Scoreboard verification at output

        Manual Error Injection phase
            -Frame error
            -Parity error
            -Baud mismatches
                -how would I do this??
            -Sending packets faster than
        
    """

    #start clock
    cocotb.start_soon(#schedules a coroutine thread (task?) to be run concurrently w/ the rest of the test
        Clock(dut.clk, 10, "ns").start()#50% duty cycle clock signal
        #1ns off, 1ns on --> 100 MHz
    )

    # Initialize input signals
    dut.rst.value = 1
    dut.tx_data.value = 0

    dut.rx_enable.value = 1
    dut.tx_data_ready.value = 0 
    dut.uart_rxd.value = 0

    dut.baud_sel.value = 0b10 #2'b10

    # Toggle first reset
    await Timer(100, unit="ns")
    dut.rst.value = 0
    await Timer(100, unit="ns")
    dut._log.info("Initial Reset done")

    scoreboard = Queue()
    numberOfPackets = 10
    packetsRecv = []

    # both of these tasks are set to run at the same time
    tx_task = cocotb.start_soon(tx_scoreboard(dut, scoreboard, numberOfPackets))
    rx_task = cocotb.start_soon(rx_monitor(dut, scoreboard, numberOfPackets,packetsRecv))

    # system waits for tx to end then waits for rx
    await tx_task
    await rx_task    

    # Make sure no extra (duplicate) frames show up afterwards
    await Timer(200, unit="us")
    assert len(packetsRecv) == numberOfPackets, f"Got {packetsRecv} frames, expected {numberOfPackets}"
    


### OTHER CO-ROUTINES
async def tx_scoreboard(dut,scoreboard,numPackets):
    for index in range(numPackets): #Packet Gen Loop
        await FallingEdge(dut.clk)
        while dut.tx_full_flag.value == 1: #wait for request slot to be free
                await FallingEdge(dut.clk)
            
        #generate data,tell system its ready
        current_tx_data = random.randint(0,255)
        dut.tx_data.value = current_tx_data
        dut.tx_data_ready.value = 1
        #add to scoreboard
        await scoreboard.put(current_tx_data)
        dut._log.info(f"[PACKET #{index}] PUT INTO SCOREBOARD: {current_tx_data:#b}")
        #sent bit will be captured before the next falling edge
        await FallingEdge(dut.clk)
        assert dut.tx_full_flag.value == 1, f"Why did it not enter the request queue?, {dut.tx_full_flag.value}"
        dut.tx_data_ready.value = 0

async def rx_monitor(dut,scoreboard,numPackets,packetsRev):
    #wait for rx data to be ready for each packet
    for index in range(numPackets):
        while int(dut.rx_data_ready.value) != 1: # wait for data to be ready
            await RisingEdge(dut.clk)
        expected_packet = await scoreboard.get()
        packetsRev.append(expected_packet)
        dut._log.info(f"[PACKET #{index}] REMOVED FROM SCOREBOARD: {str(bin(expected_packet))}, raw received: {str(dut.rx_data.value)}")
        received_packet = dut.rx_data.value

        assert received_packet == expected_packet, (
            f"[PACKET #{index}] Data Mismatch! Sent: {expected_packet:#b}, Got: {received_packet:#b}"
        )
        # --> ":#x" formats the string to hexadecimal
        #   : --> tells system to expect formatting
        #   # --> tells system to include format specificer in the front (0b for binary, 0x for hexa)
        #   x --> tells system to convert to hexadecimal
        assert dut.rx_errors.value == 0, (
            f"[PACKET #{index}] RX Error Flagged: {dut.rx_errors.value.binstr}"
        )

        if index >= (numPackets-1): #if this is the last packet just leave bruh
            break

        dut._log.info(f"rx_data_ready={int(dut.rx_data_ready.value)}")
        await ReadOnly()
        dut._log.info(f"rx_data_ready={int(dut.rx_data_ready.value)}")
        while int(dut.rx_data_ready.value) == 1: # wait for data to not be ready (meaning another packet has been received)
            # In rx_monitor, add logging:
            dut._log.info(f"Index {index}: rx_data_ready={int(dut.rx_data_ready.value)}, state=?")
            await RisingEdge(dut.clk)
            await ReadOnly()