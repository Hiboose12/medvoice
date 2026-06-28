from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import time

def get_console_logs():
    options = Options()
    options.add_argument('--headless')
    # Connect to the running flutter app
    driver = webdriver.Chrome(options=options)
    
    print("Navigating to app...")
    driver.get("http://localhost:52662/#/admin/audit-logs")
    
    print("Waiting for 3 seconds...")
    time.sleep(3)
    
    print("Fetching console logs...")
    for entry in driver.get_log('browser'):
        print(entry)
        
    driver.quit()

if __name__ == "__main__":
    get_console_logs()
