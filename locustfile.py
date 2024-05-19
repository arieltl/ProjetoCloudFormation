import random
from locust import HttpUser, between, task


def get_opponent(id):
    return str(random.choice([x for x in range(1,5) if x != id]))

class AwesomeUser(HttpUser):
    host = "http://addLoadBalancerDNS.com"
    

    wait_time = between(5, 20)
    
    def on_start(self):
        # start by waiting so that the simulated users 
        # won't all arrive at the same time
        self.user_name = str(random.randint(1,4))
        self.wait()
        self.auth()
    def auth(self):
        print("auth2")
        r = self.client.post("/index", {
            "username": self.user_name
        })

    @task(100)
    def index_page(self):
        r = self.client.get("")

    @task(1)
    def create_game(self):
        opponent = get_opponent(self.user_name)
        r = self.client.post("/play", {
            "invitee": str(opponent),
        })
   