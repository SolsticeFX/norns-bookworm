import sys
import serial
import time

if __name__ == '__main__':
    # if connected via USB cable
    #ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=1) #9600 is baud rate(must be same with that of NodeMCU)
    # if connected via serial Pin(RX, TX)
    ser = serial.Serial('/dev/ttyAMA0', 115200, timeout=1) #9600 is baud rate(must be same with that of NodeMCU)
    ser.flush()
if True:
        string = "COLOR1=" + str(sys.argv[1])
      #  string = "COLOR1=FFFFFF"
        string = string.encode('utf_8')
        ser.write(string) #sending over UART
        time.sleep(0.5)
        string = "COLOR2=" + str(sys.argv[2])
        string = string.encode('utf_8')
        ser.write(string)
        time.sleep(0.5)
        string = "COLOR3=" + str(sys.argv[3])
        string = string.encode('utf_8')
        ser.write(string)
        time.sleep(0.5)
        string = "COLOR4=" + str(sys.argv[4])
        string = string.encode('utf_8')
        ser.write(string)
        time.sleep(0.5) #delay of 1 second
        string = "MULTIUPDATE".encode('utf_8')
        ser.write(string)
