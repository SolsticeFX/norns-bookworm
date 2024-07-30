
import serial
import time
if __name__ == '__main__':
    # if connected via USB cable
    #ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=1) #9600 is baud rate(must be same with that of NodeMCU)
    # if connected via serial Pin(RX, TX)
    ser = serial.Serial('/dev/ttyAMA0', 115200, timeout=1) #9600 is baud rate(must be same with that of NodeMCU)
    ser.flush()
    ser2 = serial.Serial('/dev/ttyAMA2', 38400, timeout=1) #9600 is baud rate(must>
    ser2.flush()
if True:
#        string = input("enter string:") #input from user
        string = "boot"
#        string = string + "\n"
        string = string.encode('utf_8')
        ser.write(string)
        ser.flush()
        ser2.write(string)
        ser2.flush()
        # time.sleep(1) #delay of 1 second





