# Scalable Information Extraction System

Design Documentation by Aaron Taylor <br/>
&copy; 2014 Peck, LLC. <br/>
For Internal Distribution only

## Useful techniques
- Machine Learning decision making
 - determining whether or not a page contains calendaring information
- Information Extraction
 - pulling useful information out of relatively unstructured data

## Multistage System Layout Planning
 To create a scalable system, it is helpful to break the system up into pieces which perform defined tasks within the process of gathering data to input to our system

 The first phase must establish training datasets which will allow the system to differentiate between pages that contain calendaring information in aggregate, those that contain information about specific events (likely linked to from the aggregate calendaring pages), and those that contain no calendaring information and are thus uninteresting to us. This will be the first stage of the process, cataloging the applicable pages or APIs for an institution so that they can be quickly scraped once in the system.

 The second phase of the process is to create a system to gather the necessary information to systematically extract calendaring data from the cataloged websites. This process should ascertain the CSS selectors or other identifying features of the calendaring information within the HTML code and then catalog these specific attributes so that the iterative scraping process can be as efficient as possible and not require additional processing for material that has already been analyzed.

 The third phase utilizes the results of the previous analyses of the site to scrape the institutional websites at automated intervals. This system will accept as input a set of URLs and associated with each of these will be a set of CSS selectors to locate the relevant calendaring information. If the webpage is of the same of similar format as at the time when the analysis was done, this information will be gathered and stored locally for final verification. This framework can be designed such that it is not specific to calendaring information or institutional websites, but rather a generalized scraping process based on structured input.

 The fourth phase will inspect the outputted data scraped during the previous phase and verify that it is intelligible and in the proper format, while containing all the necessary information. If the scraped data passes the necessary tests, then it will be inputted into the database in the existing form. A certain small numbers of detected errors will be allowed and logged appropriately with appropriate notifications passed send to the administrator of the system. A number of errors amounting beyond the allowed total will trigger the analysis processes in phase 2 to be re-run for the offending URLs, notifying the system administrators as necessary.

 If all is well, the data outputted into the database in phase 4 will be immediately available to users of the app on the next executed database query. Possible additions to this system may include the ability for manual edits or additions to the results of the analysis processes, such as providing new training data to modify the algorithms and decision processes for selecting classes of each page instance, or even modification of the decision making models.

### Challenges
1. First Phase: Page Class Cataloging
 - creating decision making models to determine page type
 - which attributes to look for, what defined calendar information and how is this reflected in a website
2. Second Phase: Page IE Analysis
 - looking for grouped information specific to each event
 - providing appropriate annotations applicable to the training set
 - determining the best format to hand off to the scraping process for expedited repetitive scraping
 - allowing for flexibility in the outputted models that will not break on daily updates, such as eliminating unnecessary tags or information that are overly explicit
3. Third Phase: Automated Content Scraping
 - spreading the load between sites to avoid being locked out by institutional systems
 - handling changes in data format, ensuring that the process is as robust as possible
 - executing graceful degradation in the case that something does break or get stuck
4. Fourth Phase: Content Verification
 - recognizing errors that passed through the analysis and scraping processes
 - determining when a page analysis is sufficiently broken to result in its renewal

## Target HTML Analysis

A high-level analysis of the structure of our target content, starting with the simplest cases. There are some bigger subcategories that  Will include a few specific examples for illustrative purposes.

### Single Nesting

Fully nested data is the simplest to parse because all the information on a specific instance of a model is self-contained within a single HTML node, allowing that node to be programatically analyzed in isolation from the rest of the page to form that instance of the model.

#### RSS Feeds

RSS feeds are the most common example of the single nested model. They consist of top-level item selectors which each contain tags named to specify the attributes for that object. This forms a two-level nesting that can be handles programmatically in a relatively simple manner by iterating over the child selectors for each node returned by the top-level selector for the scrape resource.

### Multi-Level Nesting

Multi-level nested data representation requires a more dynamic programming approach because the number of nesting levels cannot be relied upon in the code as it is with single nesting. Instead, the code must be able to traverse down through an unknown number of levels of HTML data. This can be accomplished using recursive techniques, which may be harder to manage at a larger scale, or through breadth-first traversals similar to the operation fo a crawler. The main issue is ensuring that the multi-level parent data is associated with the correct child data upon model creation.

#### Middlebury Dining Menus

The html at http://menus.middlebury.edu is a perfect example of a multi-level nested structure, with each Dining Hall at the highest level containing multiple meals, which in turn contain multiple menu items for the specific meal and dining hall.

### Sibling Model

The sibling model steps of up the complexity of the representation of HTML within the webpage because rather than being contained in self-contained units, the data fields for multiple instances of the same model are contained on the same level. While they usually match up one-to-one, there is the potential presented here for mis-matching attributes with each other because child relationships are not explicit.

### Pagination

There are the main cases here that can be dealt with in a method of increasing complexity.

- URL iteration with direct parameters
- simple form submission with `Mechanize`
- Browser simulation to handle AJAX with the ruby Selenium wrapper `watir-webdriver`

The necessary method and the form that the method must take, including what the iterative input to the traversal model looks like, must all be stored in the Data model. This will likely require additions to the current. Each page can be analyzed in isolation by other analysis tools that focus on just the content data on the page.

## Data Model

The cornerstone of this system is a way to comprehensively store the information required to be able to repeatedly and rapidly extract data from a webpage. This data model must be structured to handle the whole range types of event and other data that our system wil be scraping. By breaking up the storage of this information into an inter-related hierarchy of database tables, the stored data can be iterated over to access new information displayed in the same format as the originally analyzed content.

Just as with breaking up the system nto separate phases, structuring this data allows the large scope of this problem to be broken down into understandable pieces thtat together are able to handle the requirements for our scraping system.

### Crawling (Phase One)

- `CrawlSeed`
 - the urls and constraining regexes that are used by phase one of the process to seed the crawlers traversal of an institution's entire website.

### Scraping (Phase Two and Three)

- `RsourceType`
 - Relates directly to a `ActiveRecord::Base` subclass model that stores the data for this resource type
 - has many `DataResource` and `ScrapeResource` objects, described below
- `ScrapeResource`
 - URLs associated with a specific resource type
 - contain other information about this resource, including the appropriate scrape interval (this may need to be changed to work with sidetiq) and a validation flag to indicatie whether the resource should be used in production
- `DataResource`
 - belongs to a single resource type
 - has many selectors (described below)
 - used to keep track of the column name within its resource type's model for use with each selector that belongs to this data resource
- `Selector`
 - a specific CSS selector on a web page that contains important piece(s) of data
 - belongs to a single `DataResource` and a single `ScrapeResource` which in turn define and identical `ResourceType` for this `Selector`
 - can belong to other parent selectors stored in the table that are indicated as Top Level selectors.
 - In the fully nested model, the children of a Top Level selector are directly associated with a model through the inferred resource type, and the children of the selector are the attributes within that model instance.

## Implementation

### Phase One: Crawling

A crawler written in ruby currently has the ability to perform a breadth-first traversal of a website with a decent amount of reliability. More work is needed here to make the crawler more robust.

### Phase Two: Page Parsing

For now, we have some rudimentary URL filters that find RSS and iCal feeds and store those in the database.

For the initial round of institutions, most of this will likely be a manual process through the Admin pages for the Data Model used by phase 3.

### Phase Three: Repeated Scraping

Uses the information in the database to repeatedly scrape the web pages using `sidetiq`

The current system handles the fully nested

### Phase Four

The validations planned for phase four currently consist of a `concern` that extends the `ActiveRecord::Base` class to make saving and creating model objects idempotent.

More work is obviously needed here to ensure that data is still valid as web pages change. Additionally, the issue of updates to existing data is not considered. We may need to add information to our data model to keep track of whether of not a piece of content in the database was found in the latest scrape that was run. If not, it may have been cancelled and needs to be dealt with appropriately.

## Production Scraping Process
Step by step walk through of the deployed system. Will be adding details on the final implementation as they are determined and become available.

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

### Ruby Gems
- Nokogiri
 - highly capable HTML and XML parsing
 - Documentation: http://nokogiri.org
 - Source: https://github.com/sparklemotion/nokogiri
- Mechanize
 - link traversal and simple form submission
 - Documentation: http://docs.seattlerb.org/mechanize/
 - Source: https://github.com/sparklemotion/mechanize
- Watir Webdriver: wrapper for Selenium

### Crawlers
 - Nutch Web Crawler from the Apache project

### Machine Learning Decision Making

### Information Extraction
