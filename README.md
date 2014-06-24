# Scraping

Design Documentation written by Aaron Taylor

## Useful techniques
- Machine Learning decision making
 - determining whether or not a page contains calendaring information
- Information Extraction
 - pulling useful information out of unstructured data


## Creating the system
 To create a scalable system, it is helpful to break the system up into pieces which perform defined tasks within the process of gathering data to input to our system

 The first phase must establish training datasets which will allow the system to differentiate between pages that contain calendaring information in aggregate, those that contain information about specific events (likely linked to from the aggregate calendaring pages), and those that contain no calendaring information and are thus uninteresting to us. This will be the first stage of the process, cataloging the applicable pages or APIs for an institution so that they can be quickly scraped once in the system.

 The second phase of the process is to create a system to gather the necessary information to systematically extract calendaring data from the cataloged websites. This process should ascertain the XPath selectors or other identifying features of the calendaring information within the HTML code and then catalog these specific attributes so that the iterative scraping process can be as efficient as possible and not require additional processing for material that has already been analyzed.

 The third phase utilizes the results of the previous analyses of the site to scrape the institutional websites at automated intervals. This system will accept as input a set of URLs and associated with each of these will be a set of XPath selectors to locate the relevant calendaring information. If the webpage is of the same of similar format as at the time when the analysis was done, this information will be gathered and stored locally for final verification. This framework can be designed such that it is not specific to calendaring information or institutional websites, but rather a generalized scraping process based on structured input.

 The fourth phase will inspect the outputted data scraped during the previous phase and verify that it is intelligible and in the proper format, while containing all the necessary information. If the scraped data passes the necessary tests, then it will be inputted into the database in the existing form. A certain small numbers of detected errors will be allowed and logged appropriately with appropriate notifications passed send to the administrator of the system. A number of errors amounting beyond the allowed total will trigger the analysis processes in phase 2 to be re-run for the offending URLs, notifying the system administrators as necessary.

 If all is well, the data outputted into the database in phase 4 will be immediately available to users of the app on the next executed database query. Possible additions to this system may include the ability for manual edits or additions to the results of the analysis processes, such as providing new training data to modify the algorithms and decision processes for selecting classes of each page instance, or

## Production Scraping Process

### New Institution

1. Crawler traverses all pages within the institution's domain.
- For each page, establish its class of content and catalog appropriately
 - bulk calendaring data
 - individual event data
 - no calendaring data.
- Process the instances of bulk calendaring class
 - establish all relevant information available at that level
 - record format of links to the event detail pages
- For each processed bulk calendaring page, analyze

### Existing Institution

1. At automated time intervals, scrape the cataloged resources for each URL and associated XPath locations, put them through the integrity verification process in phase 4, and input them into the database if possible
- Special handling is required for certain types of information
 - Dining menus
 - Athletic event scores (more frequent updates)
 - Administrative notifications and messages (if supported)

## Utilized Open Source Software Libraries

Chosen software libraries and their intended usage to be described here. Check the wiki for possible contenders.
