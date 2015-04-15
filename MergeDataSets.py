import argparse
import json
import pprint
import os
import sys
import urllib
import urllib2
import oauth2
import ConfigParser


API_HOST = 'api.yelp.com'
SEARCH_LIMIT = 40
SEARCH_PATH = '/v2/search/'
PHONE_SEARCH_PATH = '/v2/phone_search/'
BUSINESS_SEARCH_PATH = '/v2/business/'

# OAuth credential will be loaded from config file
CONSUMER_KEY = ''
CONSUMER_SECRET = ''
TOKEN = ''
TOKEN_SECRET = ''

CONFIG_FILE = 'OAuthCredentials.config'
NYC_RESTAURANT_HEALTH_DATA_FILE = 'NYCData.json'
MERGED_DATA_FILE = 'MergedYelpAndNYCData'
NYCData_URL = 'https://data.cityofnewyork.us/api/views/xx67-kt59/rows.json'


def request(host, path, url_params=None):
    """Prepares OAuth authentication and sends the request to the API.
    Args:
        host (str): The domain host of the API.
        path (str): The path of the API after the domain.
        url_params (dict): An optional set of query parameters in the request.
    Returns:
        dict: The JSON response from the request.
    Raises:
        urllib2.HTTPError: An error occurs from the HTTP request.
    """
    url_params = url_params or {}
    url = 'http://{0}{1}?'.format(host, urllib.quote(path.encode('utf8')))

    consumer = oauth2.Consumer(CONSUMER_KEY, CONSUMER_SECRET)
    oauth_request = oauth2.Request(method="GET", url=url, parameters=url_params)

    oauth_request.update(
        {
            'oauth_nonce': oauth2.generate_nonce(),
            'oauth_timestamp': oauth2.generate_timestamp(),
            'oauth_token': TOKEN,
            'oauth_consumer_key': CONSUMER_KEY
        }
    )
    token = oauth2.Token(TOKEN, TOKEN_SECRET)
    oauth_request.sign_request(oauth2.SignatureMethod_HMAC_SHA1(), consumer, token)
    signed_url = oauth_request.to_url()
    
    print u'Querying {0} ... with params {1}'.format(url, url_params)

    conn = urllib2.urlopen(signed_url, None)
    try:
        response = json.loads(conn.read())
    finally:
        conn.close()

    return response


def yelpPhoneQuery(phoneNumber, zipCode):
    url_params = {
        'phone': phoneNumber
    }
    try:
    	response = request(API_HOST, PHONE_SEARCH_PATH, url_params)
    except:
    	print('Failed to lookup phone number - possibly invalid number')
    	return None

    businesses = response.get('businesses')
    if not businesses:
    	print('No businesses for {0} found.'.format(phoneNumber))
    	return
    for business in businesses:
    	if ('postal_code' in business['location']):
    		businessZipCode = business['location']['postal_code']
    		if (businessZipCode == zipCode):
    			print('Found match for {0}'.format(phoneNumber))
    			return business
    print('Phone Number match found, but no zipcode matches for {0} in {1}'.format(phoneNumber, zipCode))
    return None

def parseAndMerge(jsonData):
	print('Starting parseAndMerge')

	outputFile = open(MERGED_DATA_FILE, "w")

	prevPhone = ''
	prevZipCode = ''
	prevBusiness = ''

	totalNumberMatched = 0
	totalNumberMissed = 0
	missedList = []

	for data in jsonData:
		currentPhone = data[14]
		curentZipCode = data[13]
		if (currentPhone == prevPhone and curentZipCode == prevZipCode):
			business = prevBusiness
		else:
			business = yelpPhoneQuery(currentPhone, curentZipCode)
			prevPhone = currentPhone
			prevZipCode = curentZipCode
			prevBusiness = business
		if(business is not None):
			totalNumberMatched += 1
			outputFile.write(str(data))
			outputFile.write(str(business))
			outputFile.write('\n')
		else:
			totalNumberMissed += 1
			missedList.append(data[0])
	outputFile.close()
	print('In total, matched {0} and skipped {1}'.format(totalNumberMatched, totalNumberMissed))
	print('Here is the list of IDs missed:')
	print(missedList)


def ensureAccessToNYCData():
	print('Checking if NYCData file is already downloaded....')
	if (os.path.isfile(NYC_RESTAURANT_HEALTH_DATA_FILE)):
		print('NYCData file was found in current directory - yay!')
		return
	print('NYCData file was not found - attempting to download now...')
	dataFile = open(NYC_RESTAURANT_HEALTH_DATA_FILE, "w")
	dataUrl = urllib.urlopen(NYCData_URL)
	dataFile.write(dataUrl.read())
	dataFile.close()
	print('Downloaded and saved NYCData file to {0}'.format(NYC_RESTAURANT_HEALTH_DATA_FILE))


# TODO: might want to improve memory usage by not reading in full file
def loadNYCData():
	ensureAccessToNYCData()
	print('Loading NYCDataFile in as JSON...')
	with open(NYC_RESTAURANT_HEALTH_DATA_FILE) as NYCDataFile:
		jsonData = json.load(NYCDataFile)
		return jsonData['data']		


def loadAndSetOAuthCreds():
	print('Loading and Setting OAuthCredentials from config file...')
	configParser = ConfigParser.ConfigParser()

	if os.path.isfile(CONFIG_FILE):
		configParser.read(CONFIG_FILE)
	else:
		sys.exit('Config file with OAuthCredentials not found in current dir.')

	if (configParser.has_option('OAuthCredentials', 'CONSUMER_KEY') and
			configParser.has_option('OAuthCredentials', 'CONSUMER_SECRET') and
			configParser.has_option('OAuthCredentials', 'TOKEN') and
			configParser.has_option('OAuthCredentials', 'TOKEN_SECRET')):
		global CONSUMER_KEY
		global CONSUMER_SECRET
		global TOKEN
		global TOKEN_SECRET
		CONSUMER_KEY = configParser.get('OAuthCredentials', 'CONSUMER_KEY')
		CONSUMER_SECRET = configParser.get('OAuthCredentials', 'CONSUMER_SECRET')
		TOKEN = configParser.get('OAuthCredentials', 'TOKEN')
		TOKEN_SECRET = configParser.get('OAuthCredentials', 'TOKEN_SECRET')
	else:
		sys.exit('Config file must contain the required OAuthCredentials. Please check that it contains: CONSUMER_KEY, CONSUMER_SECRET, TOKEN, TOKEN_SECRET')

def main():
	print('Welcome to MergeDataSets.py!!')

	loadAndSetOAuthCreds()

	NYCData = loadNYCData()
	parseAndMerge(NYCData)


if __name__ == '__main__':
    main()