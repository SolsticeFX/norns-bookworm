import sys
import serial
import time

if __name__ == '__main__':
    # if connected via USB cable
    #ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=1) #9600 is baud rate(must be same with that of NodeMCU)
    # if connected via serial Pin(RX, TX)
        ser = serial.Serial('/dev/ttyAMA2', 38400, timeout=1)
        ser.flush()
if True:


        string = "DEBUG=" + str(sys.argv[1])
        #string = "COLOR1=FFFFFF"
        string = string.encode('utf_8')
        ser.write(string) #sending over UART
        time.sleep(0.5)
        string = "UARTMIDI=" + str(sys.argv[2])
        string = string.encode('utf_8')
        ser.write(string)
        time.sleep(0.5)
        string = "USBMIDI=" + str(sys.argv[3])
        string = string.encode('utf_8')
        ser.write(string)
        time.sleep(0.5)
        string = "BTMIDI=" + str(sys.argv[4])
        string = string.encode('utf_8')
        ser.write(string)
        time.sleep(0.5) #delay of 1 second
        string = "WIFIMONITOR=" + str(sys.argv[5])
        string = string.encode('utf_8')
        ser.write(string)
        time.sleep(0.5) #delay of 1 second
        string = "WIFIMIDI=" + str(sys.argv[6])
        string = string.encode('utf_8')
        ser.write(string)
        time.sleep(0.5)
        string = "OTA=" + str(sys.argv[7])
        string = string.encode('utf_8')
        ser.write(string)
        time.sleep(0.5)
        string = "restart"
        string = string.encode('utf_8')
        ser.write(string)
        