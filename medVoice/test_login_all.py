import requests

demo_users = [
    ("johndoe", "demo123"),
    ("cityhospital", "demo123"),
    ("healthauth", "demo123"),
    ("superadmin", "demo123")
]

login_url = "http://localhost:8000/login/"
profile_url = "http://localhost:8000/api/user/"

for username, password in demo_users:
    session = requests.Session()
    print(f"\n--- Testing {username} ---")
    response = session.post(
        login_url,
        data={"username": username, "password": password},
        headers={"Accept": "application/json", "X-Requested-With": "XMLHttpRequest"}
    )
    print("Login Status:", response.status_code)
    print("Login Body:", response.text)
    
    if response.status_code == 200:
        response2 = session.get(
            profile_url,
            headers={"Accept": "application/json", "X-Requested-With": "XMLHttpRequest"}
        )
        print("Profile Status:", response2.status_code)
        print("Profile Body:", response2.text)
