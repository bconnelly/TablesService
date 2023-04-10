import requests
import json
import random
import os

LOAD_BALANCER=os.environ.get("RC_LB")
SERVICE_PATH="RestaurantService"
CUSTOMER_NAME=random.randint(0,10000)

print(CUSTOMER_NAME)

retryCount = 3
for i in range(retryCount):
    print("Pinging /seatCustomer...")
    response = requests.post("http://" + LOAD_BALANCER + "/" + SERVICE_PATH + "/seatCustomer", data = {'firstName':CUSTOMER_NAME, 'address':'someaddress','cash':1.23})
    print("response: " + str(response.status_code))
    if response.status_code == 200: break
    # if this was the last try and we didn't get a 200, fail
    if retryCount == 2: exit(1)

for i in range(retryCount):
    print("Pinging /getOpenTables...")
    response = requests.get("http://" + LOAD_BALANCER + "/" + SERVICE_PATH + "/getOpenTables")
    print("response: " + str(response.status_code))
    if response.status_code == 200: break
    # if this was the last try and we didn't get a 200, fail
    if retryCount == 2: exit(1)

for i in range(retryCount):
    print("Pinging /submitOrder...")
    response = requests.post("http://" + LOAD_BALANCER + "/" + SERVICE_PATH + "/submitOrder", data = {'firstName':CUSTOMER_NAME, 'tableNumber':'1', 'dish':'food', 'bill':1.00})
    print("response: " + str(response.status_code))
    if response.status_code == 200: break
    # if this was the last try and we didn't get a 200, fail
    if retryCount == 2: exit(1)

for i in range(retryCount):
    print("Pinging /bootCustomer...")
    response = requests.post("http://" + LOAD_BALANCER + "/" + SERVICE_PATH + "/bootCustomer", data = {'firstName':CUSTOMER_NAME})
    print("response: " + str(response.status_code))
    if response.status_code == 200: break
    # if this was the last try and we didn't get a 200, fail
    if retryCount == 2: exit(1)