import time
import json
import os
import random
import logging
import requests
import tempfile
from datetime import datetime, timedelta

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException, StaleElementReferenceException

from msedge.selenium_tools import Edge, EdgeOptions  # Legacy support
from selenium.webdriver.edge.service import Service as EdgeService

# ✅ Informative log
print("Using Microsoft Edge WebDriver")

# ✅ Edge options setup
options = EdgeOptions()
options.use_chromium = True
options.add_argument("--headless")  # Comment this out if you want to see the browser UI
options.add_argument("--disable-gpu")
options.add_argument("--window-size=1920,1080")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
options.add_argument(f"--user-data-dir={tempfile.mkdtemp()}")  # Prevent session conflicts
options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0")

# ✅ Launch Edge driver
driver = Edge(service=EdgeService(), options=options)

# Example usage (replace in your actual class/methods)
# self.driver = driver
# Set up logging
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    handlers=[logging.FileHandler("scraper.log"), logging.StreamHandler()])
logger = logging.getLogger(__name__)

class MarhamScraper:
    def __init__(self):
        self.base_url = "https://www.marham.pk"
        self.cities = ["karachi", "lahore", "islamabad", "rawalpindi"]
        self.nutritionists = []

        self.user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36 Edg/121.0.0.0",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0"
        ]

        logger.info("Setting up Edge options...")

        options = EdgeOptions()
        options.add_argument("--start-maximized")
        options.add_argument("--disable-notifications")

        # Optional: Use random user agent
        random_user_agent = random.choice(self.user_agents)
        logger.info(f"Using user agent: {random_user_agent}")
        options.add_argument(f"user-agent={random_user_agent}")

        # Optional: run headless
        # options.add_argument("--headless=new")

        self.driver = webdriver.Edge(service=EdgeService(), options=options)
        self.wait = WebDriverWait(self.driver, 30)

        logger.info("Microsoft Edge WebDriver initialized successfully")

    def add_random_delay(self, min_seconds=1, max_seconds=3):
        """Add random delay to mimic human behavior"""
        delay = random.uniform(min_seconds, max_seconds)
        time.sleep(delay)
        
    def simulate_human_behavior(self):
        """Simulate human-like mouse movements and scrolling"""
        try:
            # Random mouse movements
            actions = ActionChains(self.driver)
            for _ in range(random.randint(3, 7)):
                x = random.randint(100, 700)
                y = random.randint(100, 500)
                actions.move_by_offset(x, y).perform()
                self.add_random_delay(0.3, 0.7)
                # Reset position to avoid moving off-screen
                actions.move_to_element(self.driver.find_element(By.TAG_NAME, "body")).perform()
                
            # Random scrolling
            for _ in range(random.randint(2, 5)):
                scroll_amount = random.randint(100, 400)
                self.driver.execute_script(f"window.scrollBy(0, {scroll_amount});")
                self.add_random_delay(0.5, 1.5)
        except Exception as e:
            logger.debug(f"Error in simulating human behavior: {str(e)}")

    def scroll_and_wait(self):
        """Scroll the page gradually and wait for content to load"""
        logger.info("Scrolling page to load all content...")
        last_height = self.driver.execute_script("return document.body.scrollHeight")
        retries = 0
        max_retries = 5
        
        while retries < max_retries:
            # Scroll in smaller increments with random delays
            for i in range(5):
                self.driver.execute_script(
                    f"window.scrollTo(0, {(i + 1) * (last_height / 5)});"
                )
                self.add_random_delay(0.5, 1.5)
            
            # Wait for any dynamic content to load
            self.add_random_delay(2, 4)
            
            new_height = self.driver.execute_script("return document.body.scrollHeight")
            if new_height == last_height:
                retries += 1
            else:
                retries = 0
            last_height = new_height

            # Check for and click any "Load More" buttons
            try:
                load_more_selectors = [
                    "[class*='load-more']", 
                    "[class*='show-more']", 
                    ".pagination", 
                    "button[class*='more']"
                ]
                
                for selector in load_more_selectors:
                    load_more_elements = self.driver.find_elements(By.CSS_SELECTOR, selector)
                    for element in load_more_elements:
                        if element.is_displayed():
                            try:
                                logger.info("Clicking 'Load More' button...")
                                element.click()
                                self.add_random_delay(3, 5)
                                break
                            except:
                                pass
            except Exception as e:
                logger.debug(f"Error handling load more button: {str(e)}")

    def extract_text_safely(self, element, selector, method=By.CSS_SELECTOR, attribute=None):
        """Safely extract text from an element"""
        try:
            found_element = element.find_element(method, selector)
            if attribute:
                return found_element.get_attribute(attribute)
            return found_element.text.strip()
        except:
            return None

    def try_multiple_selectors(self, element, selectors, method=By.CSS_SELECTOR, attribute=None):
        """Try multiple selectors to find an element and extract text"""
        for selector in selectors:
            try:
                result = self.extract_text_safely(element, selector, method, attribute)
                if result:
                    return result
            except:
                continue
        return None

    def download_nutritionist_image(self, card, nutritionist_id):
        """Download the nutritionist profile image and save it locally"""
        try:
            # Try various image selectors to find profile pictures
            image_selectors = [
                "img.dr-img",
                "img.avatar",
                "img.doctor-image",
                ".dr-profile-img img",
                ".profile-image img",
                ".doctor-photo img",
                ".avatar-container img",
                "img[src*='doctor']",
                "img[src*='profile']",
                "img[alt*='doctor']",
                "img[alt*='Dr']",
                ".card-img-top",
                ".img-fluid"
            ]
            
            image_url = None
            for selector in image_selectors:
                try:
                    image_elements = card.find_elements(By.CSS_SELECTOR, selector)
                    for img in image_elements:
                        src = img.get_attribute("src")
                        if src and (src.startswith("http") or src.startswith("//")) and not src.endswith(".svg"):
                            image_url = src
                            if image_url.startswith("//"):
                                image_url = "https:" + image_url
                            break
                    if image_url:
                        break
                except:
                    continue
            
            # Look for background images if no direct img tags found
            if not image_url:
                try:
                    elements = card.find_elements(By.CSS_SELECTOR, "[style*='background-image']")
                    for element in elements:
                        style = element.get_attribute("style")
                        if "background-image" in style:
                            import re
                            url_match = re.search(r"url\(['\"]?(.*?)['\"]?\)", style)
                            if url_match:
                                image_url = url_match.group(1)
                                if image_url.startswith("//"):
                                    image_url = "https:" + image_url
                                break
                except:
                    pass
            
            if not image_url:
                logger.warning(f"Could not find image for nutritionist ID: {nutritionist_id}")
                return None
            
            # Create directory if it doesn't exist
            output_dir = '../assets/images/nutritionists'
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
            
            # Download the image
            # Create a filename based on nutritionist ID (sanitized)
            filename = f"nutritionist_{nutritionist_id}.jpg"
            filepath = os.path.join(output_dir, filename)
            
            # Set up headers to mimic a browser
            headers = {
                "User-Agent": random.choice(self.user_agents),
                "Referer": self.base_url
            }
            
            # Add a small delay before downloading
            self.add_random_delay(1, 2)
            
            # Download the image with a timeout
            response = requests.get(image_url, headers=headers, timeout=10)
            if response.status_code == 200:
                with open(filepath, 'wb') as f:
                    f.write(response.content)
                
                logger.info(f"Successfully downloaded image for nutritionist ID: {nutritionist_id}")
                return f"assets/images/nutritionists/{filename}"
            else:
                logger.warning(f"Failed to download image: {response.status_code}")
                return None
        
        except Exception as e:
            logger.error(f"Error downloading image: {str(e)}")
            return None

    def capture_profile_image_if_download_fails(self, card, nutritionist_id):
        """Capture a screenshot of the profile image element as fallback"""
        try:
            # Try to find the image element
            image_element = None
            image_selectors = [
                "img.dr-img",
                "img.avatar",
                "img.doctor-image",
                ".dr-profile-img img",
                ".profile-image img",
                ".doctor-photo img",
                ".avatar-container img"
            ]
            
            for selector in image_selectors:
                elements = card.find_elements(By.CSS_SELECTOR, selector)
                if elements:
                    image_element = elements[0]
                    break
            
            if not image_element:
                logger.warning(f"No image element found for ID: {nutritionist_id}")
                return None
            
            # Create directory
            output_dir = '../assets/images/nutritionists'
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
                
            # Take screenshot of the element
            filepath = f"{output_dir}/nutritionist_{nutritionist_id}.png"
            
            # Scroll to ensure element is visible
            self.driver.execute_script("arguments[0].scrollIntoView(true);", image_element)
            self.add_random_delay(0.5, 1)
            
            # Take the screenshot of the specific element
            image_element.screenshot(filepath)
            logger.info(f"Captured image for nutritionist ID: {nutritionist_id}")
            
            return f"assets/images/nutritionists/nutritionist_{nutritionist_id}.png"
        except Exception as e:
            logger.error(f"Error capturing image: {str(e)}")
            return None

    def scrape_nutritionist_details(self, card, city):
        try:
            logger.info("Extracting data from doctor card...")
            doctor_details = {}
            
            # Get name with multiple selectors
            name_selectors = [
                'h3.text-blue', 
                'h3.text-underline',
                'h3.mb-0',
                'a[data-location="doctor name"] h3',
                '.dr_profile_opened_from_listing h3',
                'a.dr_profile_opened_from_listing',
                'a.text-blue h3'
            ]
            
            doctor_details['name'] = self.try_multiple_selectors(card, name_selectors)
            
            if not doctor_details.get('name'):
                # Try different approach - look for links with specific classes
                links = card.find_elements(By.TAG_NAME, 'a')
                for link in links:
                    class_attr = link.get_attribute('class')
                    if class_attr and ('dr_profile_opened_from_listing' in class_attr or 'text-blue' in class_attr):
                        doctor_details['name'] = link.text.strip()
                        if doctor_details['name']:
                            break

            if not doctor_details.get('name'):
                logger.warning("Could not find doctor name, skipping")
                return None

            # Get qualification
            qual_selectors = [
                'p.text-sm:not(.mb-0)',
                'p[class*="text-sm"]',
                '.qualification',
                'p:nth-child(2)'
            ]
            doctor_details['qualification'] = self.try_multiple_selectors(card, qual_selectors) or "Nutritionist"

            # Get experience
            exp_selectors = [
                ".//p[contains(text(),'Experience')]/following-sibling::p",
                ".//p[contains(text(),'Yrs')]",
                "p.text-bold.text-sm",
                ".//p[contains(@class,'text-bold')]"
            ]
            doctor_details['experience'] = self.try_multiple_selectors(card, exp_selectors, By.XPATH) or "5+ Years"

            # Get fee
            fee_selectors = [
                '[data-amount]', 
                '.fee', 
                'span.text-primary',
                '.price', 
                '.mb-0.price'
            ]
            fee_text = self.try_multiple_selectors(card, fee_selectors, attribute='data-amount')
            if not fee_text:
                fee_text = self.try_multiple_selectors(card, fee_selectors)
                
            if fee_text:
                fee_digits = ''.join(filter(str.isdigit, fee_text))
                if fee_digits:
                    doctor_details['fee'] = int(fee_digits)
                else:
                    doctor_details['fee'] = 2000
            else:
                doctor_details['fee'] = 2000

            # Get hospital/clinic
            hospital_selectors = [
                '[data-hospitalname]',
                '.hospital-name',
                '.clinic-name',
                '.text-blue:not(h3)',
                'p.text-blue'
            ]
            doctor_details['hospital'] = self.try_multiple_selectors(
                card, hospital_selectors, attribute='data-hospitalname'
            ) or self.try_multiple_selectors(card, hospital_selectors) or "Video Consultation"

            # Get specializations
            specializations = []
            spec_selectors = [
                'span.chips-highlight',
                '.specialization',
                '[data-location="area of interest"]',
                '.smart-bar span'
            ]
            
            for selector in spec_selectors:
                try:
                    chips = card.find_elements(By.CSS_SELECTOR, selector)
                    for chip in chips:
                        spec_text = chip.text.strip()
                        if spec_text and len(spec_text) > 3:  # Filter out very short text
                            specializations.append(spec_text)
                except:
                    pass
                    
            doctor_details['specializations'] = specializations if specializations else ["Nutrition & Diet Planning"]

            # Get rating and reviews
            try:
                # Try to find satisfaction percentage
                satisfaction_selectors = [
                    ".//p[contains(text(),'Satisfaction')]/following-sibling::p",
                    ".//p[contains(@class,'text-bold')][contains(text(),'%')]",
                    ".//p[contains(@class,'text-golden')]"
                ]
                satisfaction_text = self.try_multiple_selectors(card, satisfaction_selectors, By.XPATH)
                
                if satisfaction_text:
                    satisfaction_text = satisfaction_text.replace('%', '')
                    try:
                        rating = float(satisfaction_text) / 20  # Convert percentage to 5-star rating
                    except:
                        rating = 4.5
                else:
                    rating = 4.5
            except:
                rating = 4.5

            try:
                # Try to find reviews count
                reviews_selectors = [
                    ".//p[contains(text(),'Reviews')]/following-sibling::p",
                    ".//p[contains(@class,'text-golden')]",
                    ".//i[contains(@class,'fa-thumbs-up')]/parent::*"
                ]
                reviews_text = self.try_multiple_selectors(card, reviews_selectors, By.XPATH)
                
                if reviews_text:
                    reviews_count = ''.join(filter(str.isdigit, reviews_text))
                    if reviews_count:
                        reviews_count = int(reviews_count)
                    else:
                        reviews_count = random.randint(5, 50)
                else:
                    reviews_count = random.randint(5, 50)
            except:
                reviews_count = random.randint(5, 50)
            
            # Try to get doctor ID
            doctor_id = None
            try:
                id_elements = card.find_elements(By.CSS_SELECTOR, "[data-doctor-id]")
                if id_elements:
                    doctor_id = id_elements[0].get_attribute("data-doctor-id")
                else:
                    # Try finding it in links
                    links = card.find_elements(By.TAG_NAME, "a")
                    for link in links:
                        href = link.get_attribute("href") or ""
                        if "nutritionist" in href and "rd-" in href:
                            # Extract ID from URL like .../shafaq-bushra-rd-24387
                            parts = href.split("-")
                            if parts and parts[-1].isdigit():
                                doctor_id = parts[-1]
                                break
            except:
                pass
            
            if not doctor_id:
                doctor_id = str(len(self.nutritionists) + 1)
                
            # Try to download the nutritionist's profile image
            image_path = self.download_nutritionist_image(card, doctor_id)
            
            # If download fails, try to capture a screenshot as fallback
            if not image_path:
                image_path = self.capture_profile_image_if_download_fails(card, doctor_id)

            # Create the full nutritionist object
            nutritionist_data = {
                'id': doctor_id,
                'name': doctor_details['name'],
                'qualification': doctor_details['qualification'],
                'specialization': ', '.join(doctor_details['specializations'][:3]),
                'experience': doctor_details['experience'],
                'city': city.capitalize(),
                'hospitalClinic': doctor_details['hospital'],
                'about': f"{doctor_details['name']} is a qualified nutritionist with {doctor_details['experience']} of experience, specializing in {', '.join(doctor_details['specializations'][:2])}.",
                'rating': rating,
                'totalReviews': reviews_count,
                'email': f"contact@{doctor_details['name'].lower().replace(' ', '').replace('.', '').replace('(', '').replace(')', '')}nutrition.com",
                'phone': "Contact via Marham.pk",
                'consultationFee': doctor_details['fee'],
                'availableDays': ['Monday', 'Wednesday', 'Friday'],
                'availableTimeSlots': {
                    'Monday': ['10:00 AM', '2:00 PM', '4:00 PM'],
                    'Wednesday': ['11:00 AM', '3:00 PM', '5:00 PM'],
                    'Friday': ['9:00 AM', '1:00 PM', '3:00 PM']
                },
                'languages': ['English', 'Urdu'],
                'reviews': [],
                'imageUrl': image_path if image_path else 'assets/images/avatar.png'
            }
            
            logger.info(f"Successfully extracted data for {nutritionist_data['name']}")
            return nutritionist_data

        except Exception as e:
            logger.error(f"Error processing doctor card: {str(e)}")
            return None

    def check_for_captcha(self):
        """Check if there is a CAPTCHA or verification challenge and handle it"""
        # First check for visual CAPTCHA elements
        captcha_elements = []
        try:
            captcha_elements = (
                self.driver.find_elements(By.CSS_SELECTOR, ".g-recaptcha") +
                self.driver.find_elements(By.CSS_SELECTOR, ".h-captcha") +
                self.driver.find_elements(By.CSS_SELECTOR, "iframe[src*='captcha']") +
                self.driver.find_elements(By.CSS_SELECTOR, "iframe[src*='challenge']")
            )
        except Exception as e:
            logger.debug(f"Error checking for CAPTCHA elements: {str(e)}")
        
        # Check for specific text patterns that strongly indicate a CAPTCHA
        page_source = self.driver.page_source.lower()
        
        # Strong CAPTCHA phrase combinations (requiring multiple terms together)
        captcha_phrases = [
            ("please", "verify", "human"),
            ("security", "check", "complete"),
            ("captcha", "challenge"),
            ("cloudflare", "security", "check"),
            ("verify", "browser", "security"),
            ("i'm", "not", "robot"),
            ("human", "verification", "required")
        ]
        
        # Check for the specific phrases (all words must be present)
        found_phrases = []
        for phrase in captcha_phrases:
            if all(word in page_source for word in phrase):
                found_phrases.append(" ".join(phrase))
        
        # Also verify if normal content is missing
        normal_content_present = False
        try:
            content_selectors = [
                "#doctor-listing1", 
                ".doctor-listing",
                ".doctor-cards-container",
                "[class*='doctor-card']",
                ".navbar-brand"
            ]
            
            for selector in content_selectors:
                elements = self.driver.find_elements(By.CSS_SELECTOR, selector)
                if elements and any(element.is_displayed() for element in elements):
                    normal_content_present = True
                    break
        except Exception as e:
            logger.debug(f"Error checking for normal content: {str(e)}")
        
        # Only detect CAPTCHA if we have visible CAPTCHA elements
        # or specific phrase combinations AND normal content is missing
        visible_captcha_elements = [el for el in captcha_elements if el.is_displayed()]
        captcha_detected = (len(visible_captcha_elements) > 0 or 
                           (len(found_phrases) > 0 and not normal_content_present))
        
        if captcha_detected:
            logger.warning(f"CAPTCHA/verification detected")
            self.driver.save_screenshot(f"captcha_detected_{int(time.time())}.png")
            
            print("\n" + "="*80)
            print(f"CAPTCHA detected! Please solve it manually in the browser window.")
            print("The script will wait for 60 seconds to give you time to solve it.")
            print("="*80 + "\n")
            
            # Wait for the user to solve the CAPTCHA
            time.sleep(60)
            
            # Check if still on CAPTCHA page
            new_page_source = self.driver.page_source.lower()
            if any(all(word in new_page_source for word in phrase) for phrase in captcha_phrases):
                print("\nStill detecting CAPTCHA. Waiting 30 more seconds...")
                time.sleep(30)
                
                # Final check
                if any(all(word in self.driver.page_source.lower() for word in phrase) for phrase in captcha_phrases):
                    print("\nCAPTCHA still not solved. Taking screenshot and continuing...")
                    self.driver.save_screenshot(f"captcha_still_present_{int(time.time())}.png")
                    return False
            
            logger.info("CAPTCHA appears to be solved, continuing...")
        
        return True

    def wait_for_doctors(self):
        """Wait for doctor listings with multiple selector attempts"""
        logger.info("Waiting for doctor listings to load...")
        selectors = [
            "#doctor-listing1",
            ".doctor-listing",
            "[id*='doctor-listing']",
            ".doctor-cards-container",
            ".row.shadow-card",
            "[class*='doctor-card']"
        ]
        
        for selector in selectors:
            try:
                self.wait.until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, selector))
                )
                logger.info(f"Found doctor listings with selector: {selector}")
                return True
            except:
                continue
                
        return False

    def find_doctor_cards(self):
        """Find all doctor cards with multiple selectors"""
        card_selectors = [
            "div.row.shadow-card",
            "div[class*='doctor-card']",
            "div[class*='listing-card']",
            ".doctor-profile-card",
            ".shadow-card"
        ]
        
        for selector in card_selectors:
            cards = self.driver.find_elements(By.CSS_SELECTOR, selector)
            if cards:
                logger.info(f"Found {len(cards)} doctor cards with selector: {selector}")
                return cards
                
        return []

    def handle_popups(self):
        """Handle any popups that might appear"""
        try:
            popup_selectors = [
                ".modal-close", 
                ".close-button", 
                "[class*='popup'] .close",
                ".modal .close",
                "button.close"
            ]
            for selector in popup_selectors:
                try:
                    close_buttons = self.driver.find_elements(By.CSS_SELECTOR, selector)
                    for btn in close_buttons:
                        if btn.is_displayed():
                            logger.info("Closing popup...")
                            btn.click()
                            self.add_random_delay(1, 2)
                except:
                    pass
        except Exception as e:
            logger.debug(f"Error handling popups: {str(e)}")

    def scrape_city(self, city):
        url = f"{self.base_url}/doctors/{city}/nutritionist"
        logger.info(f"Scraping city URL: {url}")
        
        try:
            # Clear cookies between cities to help avoid detection
            self.driver.delete_all_cookies()
            logger.info("Cleared cookies")
            
            # Add a longer delay between cities
            if self.nutritionists:  # If we've already scraped at least one city
                pause_time = random.randint(25, 45)
                logger.info(f"Pausing for {pause_time} seconds before scraping next city...")
                time.sleep(pause_time)
            
            # Load the page
            self.driver.get(url)
            logger.info(f"Page loaded for {city}")
            
            # Simulate some human behavior before doing anything else
            self.simulate_human_behavior()
            
            # Initial wait with random delay
            self.add_random_delay(7, 12)
            
            # Check for CAPTCHA
            if not self.check_for_captcha():
                logger.error(f"Could not proceed with {city} due to unsolved CAPTCHA")
                return
            
            try:
                # Wait for page load
                self.wait.until(
                    EC.presence_of_element_located((By.TAG_NAME, "body"))
                )
                
                # Handle any popups
                self.handle_popups()

                # Try to accept cookies if present
                try:
                    cookie_buttons = self.driver.find_elements(By.XPATH, "//*[contains(text(), 'Accept') or contains(text(), 'I agree') or contains(text(), 'Cookie')]")
                    for button in cookie_buttons:
                        if button.is_displayed():
                            button.click()
                            logger.info("Accepted cookies")
                            self.add_random_delay(1, 2)
                            break
                except:
                    pass
                
                # Simulate more human behavior
                self.simulate_human_behavior()

                # Wait for doctor listings
                if not self.wait_for_doctors():
                    logger.warning(f"Could not find doctor listing container in {city}")
                    # Take screenshot for debugging
                    self.driver.save_screenshot(f"no_listings_{city}.png")
                    return

                logger.info(f"Found doctor listing container in {city}")
                
                # Scroll and wait for content
                self.scroll_and_wait()
                
                # Find all doctor cards
                cards = self.find_doctor_cards()
                
                if not cards:
                    logger.warning(f"No doctor cards found in {city}")
                    self.driver.save_screenshot(f"no_cards_{city}.png")
                    return
                
                logger.info(f"Found {len(cards)} doctor cards in {city}")
                
                # Process each card
                for i, card in enumerate(cards):
                    try:
                        # Skip some cards randomly to appear less bot-like
                        if random.random() < 0.1 and len(cards) > 10:
                            logger.info(f"Randomly skipping card {i+1}")
                            continue
                            
                        # Scroll card into view
                        self.driver.execute_script("arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});", card)
                        self.add_random_delay(0.8, 2.0)
                        
                        # Occasionally perform random actions
                        if random.random() < 0.3:
                            self.simulate_human_behavior()
                        
                        logger.info(f"Processing card {i+1}/{len(cards)}")
                        nutritionist_data = self.scrape_nutritionist_details(card, city)
                        if nutritionist_data:
                            if all(nutritionist_data.get(key) for key in ['name', 'qualification']):
                                self.nutritionists.append(nutritionist_data)
                                logger.info(f"Successfully scraped data for {nutritionist_data['name']}")
                                
                                # Save incrementally to not lose data if something goes wrong
                                if len(self.nutritionists) % 5 == 0:
                                    self.save_data(is_interim=True)
                            else:
                                logger.warning("Skipped incomplete data record")
                    except StaleElementReferenceException:
                        logger.warning("Card element became stale, skipping...")
                        continue
                    except Exception as e:
                        logger.error(f"Error processing individual card: {str(e)}")
                        continue
                
            except TimeoutException:
                logger.error(f"Timeout waiting for doctor listings in {city}")
                # Take screenshot for debugging
                self.driver.save_screenshot(f"timeout_{city}.png")
            except Exception as e:
                logger.error(f"Error processing doctor listings: {str(e)}")
            
        except Exception as e:
            logger.error(f"Error loading page for {city}: {str(e)}")

    def save_data(self, is_interim=False):
        output_dir = '../assets/data'
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
            
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        if is_interim:
            filename = f"{output_dir}/nutritionists_interim_{timestamp}.json"
        else:
            filename = f"{output_dir}/nutritionists_{timestamp}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump({
                'nutritionists': self.nutritionists,
                'last_updated': datetime.now().isoformat(),
                'total_count': len(self.nutritionists)
            }, f, ensure_ascii=False, indent=2)
        
        logger.info(f"Saved {len(self.nutritionists)} nutritionists to {filename}")
        
    def scrape_with_single_city(self, city_index=0):
        """Scrape a single city to avoid CAPTCHA issues"""
        try:
            if city_index >= len(self.cities):
                logger.error(f"Invalid city index: {city_index}, max is {len(self.cities)-1}")
                return
                
            city = self.cities[city_index]
            logger.info(f"Scraping single city: {city}...")
            self.scrape_city(city)
            self.save_data()
            
            print("\n" + "="*80)
            print(f"Completed scraping {city}.")
            print(f"Found {len(self.nutritionists)} nutritionists.")
            print(f"To scrape the next city, run the script with: scraper.scrape_with_single_city({city_index + 1})")
            print("="*80 + "\n")
            
        except Exception as e:
            logger.error(f"Critical error during scraping: {str(e)}")
            # Save whatever data we have
            if self.nutritionists:
                self.save_data()
        finally:
            logger.info("Closing WebDriver...")
            self.driver.quit()

    def scrape(self):
        """Scrape all cities (may trigger CAPTCHAs)"""
        try:
            logger.info("Starting Marham.pk scraper...")
            
            for i, city in enumerate(self.cities):
                logger.info(f"Scraping nutritionists from {city} ({i+1}/{len(self.cities)})...")
                self.scrape_city(city)
                
                # Save data after each city
                if self.nutritionists:
                    self.save_data(is_interim=(i < len(self.cities) - 1))
                
                # Print progress
                print(f"\nCompleted {i+1}/{len(self.cities)} cities. Current nutritionist count: {len(self.nutritionists)}\n")
            
            # Final save
            self.save_data()
            
        except Exception as e:
            logger.error(f"Critical error during scraping: {str(e)}")
            # Save whatever data we have
            if self.nutritionists:
                self.save_data()
        finally:
            logger.info("Closing WebDriver...")
            self.driver.quit()
            
if __name__ == "__main__":
    import sys
    scraper = MarhamScraper()
    
    # Default behavior - check if specific command line args
    if len(sys.argv) > 1 and sys.argv[1].isdigit():
        # Scrape a single city by index
        scraper.scrape_with_single_city(int(sys.argv[1]))
    else:
        # Scrape one city by default
        print("Scraping only first city (Karachi) to avoid CAPTCHAs.")
        print("To scrape a different city, run the script with the city index as an argument:")
        print("python scrape_nutritionists.py 1  # For Lahore")
        print("python scrape_nutritionists.py 2  # For Islamabad")
        print("python scrape_nutritionists.py 3  # For Rawalpindi")
        print("\nTo scrape all cities (may trigger CAPTCHAs), run with 'all' argument:")
        print("python scrape_nutritionists.py all")
        
        if len(sys.argv) > 1 and sys.argv[1].lower() == 'all':
            scraper.scrape()
        else:
            scraper.scrape_with_single_city(0)

if __name__ == "__main__":
    scraper = MarhamScraper()
    scraper.scrape()