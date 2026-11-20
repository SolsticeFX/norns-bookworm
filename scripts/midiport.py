import subprocess

text = (subprocess.check_output(['aconnect', '-l']))

word = [ t for t in text.split() if t.startswith('Client-') ]

test_string = "client 130: 'Client-130' [type=user,pid=16965]"
test_string=test_string.replace(":", "")
# printing original string 
print("The original string : " + test_string)

# using List comprehension + isdigit() +split()
# getting numbers from string 
res = [int(i) for i in test_string.split() if i.isdigit()]

# print result
print("The numbers list is :" + str(res))
