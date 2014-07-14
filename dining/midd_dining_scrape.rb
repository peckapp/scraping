require 'restclient'
require 'nokogiri'
require 'selenium-webdriver'

MIDD_MENUS = "http://menus.middlebury.edu"

driver = Selenium::WebDriver.for :firefox
driver.navigate.to MIDD_MENUS
