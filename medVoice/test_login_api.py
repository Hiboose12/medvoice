import requests

session = requests.Session()
login_url = "http://localhost:8000/login/"
profile_url = "http://localhost:8000/api/user/"

# 1. Login
response = session.post(
    login_url,
    data={"username": "johndoe", "password": "demo123"},
    headers={"Accept": "application/json", "X-Requested-With": "XMLHttpRequest"}
)
print("Login Status:", response.status_code)
print("Login Body:", response.text)

# 2. Get Profile
if response.status_code == 200:
    response2 = session.get(
        profile_url,
        headers={"Accept": "application/json", "X-Requested-With": "XMLHttpRequest"}
    )
    print("Profile Status:", response2.status_code)
    print("Profile Body:", response2.text)
