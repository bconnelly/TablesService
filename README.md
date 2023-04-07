# TablesService

A simple API made up of this microservice as well as [RestaurantService](https://github.com/bconnelly/RestaurantService), [OrdersService](https://github.com/bconnelly/OrdersService) and [CustomersService](https://github.com/bconnelly/CustomersService). Hosted in a kubernetes cluster on AWS, records stored in a MySQL RDS instance. Commits to master are only made by Jenkins script if rc branch deploys successfully.

### Scripts
- __Jenkinsfile__: script for building, testing and deploying via a jenkins server
- __Dockerfile__: used during jenkins build after maven project successfully builds and passes tests