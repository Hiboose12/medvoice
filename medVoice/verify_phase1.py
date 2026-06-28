import requests

BASE_URL = 'http://127.0.0.1:8000/api/v1/auth'

def test_auth():
    print("Testing Authentication Phase 1 Endpoints...")
    
    # 1. Register
    register_payload = {
        "first_name": "Test",
        "last_name": "User",
        "email": "testuser_phase1@example.com",
        "password": "SecurePassword123!"
    }
    
    try:
        r = requests.post(f"{BASE_URL}/patient/register/", json=register_payload)
        print(f"Register status: {r.status_code}")
        
        if r.status_code == 201:
            token = r.json().get('token')
            print("Register successful!")
        elif r.status_code == 400 and 'username' in r.text:
            print(f"Register failed (Username issue, likely already exists): {r.text}")
            token = None
        else:
            print(f"Register failed: {r.text}")
            token = None
            
        # Try login
        login_payload = {
            "email": "testuser_phase1@example.com",
            "password": "SecurePassword123!"
        }
        
        r2 = requests.post(f"{BASE_URL}/login/", json=login_payload)
        print(f"Login status: {r2.status_code}")
        if r2.status_code == 200:
            token = r2.json().get('token')
            print("Login successful!")
        else:
            print(f"Login failed: {r2.text}")
            
        # Get Current User
        if token:
            r3 = requests.get(f"{BASE_URL}/me/", headers={"Authorization": f"Token {token}"})
            print(f"Current User status: {r3.status_code}")
            if r3.status_code == 200:
                print(f"Current User: {r3.json()}")
            else:
                print(f"Current User failed: {r3.text}")
                
    except Exception as e:
        print(f"Connection failed. Is Django running? Error: {e}")
        
if __name__ == '__main__':
    test_auth()
