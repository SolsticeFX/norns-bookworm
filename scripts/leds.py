import sys
import serial
import time

if __name__ == '__main__':
    # if connected via USB cable
    #ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=1) #9600 is baud rate(must be same with that of NodeMCU)
    # if connected via serial Pin(RX, TX)
    ser = serial.Serial('/dev/ttyAMA0', 38400, timeout=1) #9600 is baud rate(must be same with that of NodeMCU)
    ser.flush()
if True:
        string = "BRIGHTNESS=" + str(sys.argv[1])
        string = string.encode('utf_8')
        ser.write(string) #sending over UART
#        time.sleep(1) #delay of 1 second


