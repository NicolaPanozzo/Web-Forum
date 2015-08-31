-- creating tables

CREATE TABLE UserStatus (
   StatusDescription VARCHAR(30) PRIMARY KEY
);

CREATE TABLE Gender (
   Gender VARCHAR(10) PRIMARY KEY
);

CREATE TABLE TimeZone (
   TimeZone VARCHAR(100) PRIMARY KEY
);

/* OnlineStatus is 0 if user is offline, 1 if user is online
Karma is initially 1 for all newly created users
*/
CREATE TABLE Users (
   UserName VARCHAR(50) PRIMARY KEY,
   Avatar VARCHAR(100) NOT NULL,
   JoinDate DATE NOT NULL,
   OnlineStatus INTEGER DEFAULT 0 NOT NULL,
   LastVisitDate DATE NOT NULL,
   Karma INTEGER DEFAULT 1 NOT NULL,
   NumberOfPosts INTEGER DEFAULT 0 NOT NULL,
   StatusDescription VARCHAR(30) NOT NULL REFERENCES UserStatus,
   Gender VARCHAR(10) NOT NULL REFERENCES Gender,
   TimeZone VARCHAR(100) NOT NULL REFERENCES TimeZone,
   CHECK(OnlineStatus IN (0, 1))
);

CREATE TABLE CommunityProfile(
  Username VARCHAR(50) PRIMARY KEY REFERENCES Users ON DELETE CASCADE,
  UserLocation VARCHAR(50),
  FavoriteQuote VARCHAR(100),
  WhatIDoForALiving VARCHAR(50),
  Interests VARCHAR(50),
  YearsInMarket VARCHAR(50),
  SkillTestingQuestion VARCHAR(100)
);

CREATE TABLE AlbumCategory(
  AlbumCategory VARCHAR(20) PRIMARY KEY
);

CREATE TABLE Album(
  AlbumID INTEGER PRIMARY KEY,
  AlbumName VARCHAR(30) NOT NULL,
  AlbumDescription VARCHAR(100) NOT NULL,
  CreationDate DATE NOT NULL,
  Username VARCHAR(50) NOT NULL REFERENCES Users ON DELETE CASCADE,
  AlbumCategory VARCHAR(20) NOT NULL REFERENCES AlbumCategory
);

CREATE TABLE Photo(
  PhotoID INTEGER PRIMARY KEY,
  PhotoLink VARCHAR(100) NOT NULL,
  PhotoDescription VARCHAR(50),
  AlbumID INTEGER NOT NULL REFERENCES Album ON DELETE CASCADE
);

CREATE TABLE Forum(
  ForumID INTEGER PRIMARY KEY,
  Title VARCHAR(50) NOT NULL,
  Description VARCHAR(250) NOT NULL
);

-- if a thread is sticky then the value Sticky is set to 1 else it is 0
-- a sticky thread always shows on top of the list in the user interface of the web application
CREATE TABLE ForumThread(
  ThreadID INTEGER PRIMARY KEY,
  Title VARCHAR(50) NOT NULL,
  ThreadDate DATE NOT NULL,
  Sticky INTEGER DEFAULT 0 NOT NULL,
  ThreadViews INTEGER DEFAULT 0 NOT NULL,
  UserName VARCHAR(50) NOT NULL REFERENCES Users,
  ForumID INTEGER NOT NULL REFERENCES Forum ON DELETE CASCADE,
  CHECK(Sticky IN (0, 1))
);

CREATE TABLE Post(
  PostID INTEGER PRIMARY KEY,
  PostNumber INTEGER NOT NULL,
  PostContent VARCHAR(500) NOT NULL,
  PostDate DATE NOT NULL,
  UserName VARCHAR(50) NOT NULL REFERENCES Users,
  ThreadID INTEGER NOT NULL REFERENCES ForumThread
);

CREATE TABLE ReportType(
  ReportType VARCHAR(20) PRIMARY KEY
);

CREATE TABLE ReportPost(
  UserName VARCHAR(50) NOT NULL REFERENCES Users ON DELETE CASCADE,
  PostID INTEGER NOT NULL REFERENCES Post ON DELETE CASCADE,
  ReportPostDate DATE NOT NULL,
  ReportPostComment VARCHAR(20),
  ReportType VARCHAR(20) NOT NULL REFERENCES ReportType,
  PRIMARY KEY(UserName, PostID)
);

CREATE TABLE Karma(
  UserName VARCHAR(50) NOT NULL REFERENCES Users,
  PostID INTEGER NOT NULL REFERENCES Post,
  KarmaDate DATE NOT NULL,
  KarmaComment VARCHAR(20),
  PRIMARY KEY(UserName, PostID)
);

CREATE TABLE Quote(
  QuotingPost INTEGER NOT NULL REFERENCES Post,
  QuotedPost INTEGER NOT NULL REFERENCES Post,
  PRIMARY KEY(QuotingPost, QuotedPost)
);

CREATE TABLE Tag(
  Tag VARCHAR(50) PRIMARY KEY
);

CREATE TABLE ThreadTag(
  ThreadID INTEGER NOT NULL REFERENCES ForumThread,
  Tag VARCHAR(50) NOT NULL REFERENCES Tag,
  PRIMARY KEY(ThreadID, Tag)
);

CREATE TABLE Article(
  ArticleID INTEGER PRIMARY KEY,
  ArticleDate DATE NOT NULL,
  ArticleTitle VARCHAR(30) NOT NULL,
  ArticleContent VARCHAR(1000) NOT NULL,
  ArticleSummary VARCHAR(300),
  ArticleViews INTEGER DEFAULT 0 NOT NULL,
  UserName VARCHAR(50) NOT NULL REFERENCES Users
);

CREATE TABLE ArticleTag(
  ArticleID INTEGER NOT NULL REFERENCES Article,
  Tag VARCHAR(50) NOT NULL REFERENCES Tag,
  PRIMARY KEY(ArticleID, Tag)
);

CREATE TABLE ArticleComment(
  UserName VARCHAR(50) NOT NULL REFERENCES Users,
  ArticleID INTEGER NOT NULL REFERENCES Article,
  ArticleCommentDate DATE NOT NULL,
  ArticleComment VARCHAR(100) NOT NULL,
  PRIMARY KEY(UserName, ArticleID)
);

CREATE TABLE ReportArticle(
  UserName VARCHAR(50) NOT NULL REFERENCES Users,
  ArticleID INTEGER NOT NULL REFERENCES Article,
  ReportArticleDate DATE NOT NULL,
  ReportArticleComment VARCHAR(20),
  ReportType VARCHAR(20) NOT NULL REFERENCES ReportType,
  PRIMARY KEY(UserName, ArticleID)
);

-- creating sequences and triggers for keys that 
-- count

-- for Album table
CREATE SEQUENCE AlbumID_Seq;
CREATE OR REPLACE TRIGGER AlbumID_trig
BEFORE INSERT ON Album
FOR EACH ROW
BEGIN
  SELECT AlbumID_seq.nextval INTO :new.AlbumID FROM dual;
END;
/

-- for Photo table
CREATE SEQUENCE PhotoID_Seq;
CREATE OR REPLACE TRIGGER PhotoID_trig
BEFORE INSERT ON Photo
FOR EACH ROW
BEGIN
  SELECT PhotoID_seq.nextval INTO :new.PhotoID FROM dual;
END;
/

-- for Forum table
CREATE SEQUENCE ForumID_Seq;
CREATE OR REPLACE TRIGGER ForumID_trig
BEFORE INSERT ON Forum
FOR EACH ROW
BEGIN
  SELECT ForumID_seq.nextval INTO :new.ForumID FROM dual;
END;
/

-- for ForumThread table
CREATE SEQUENCE ThreadID_Seq;
CREATE OR REPLACE TRIGGER ThreadID_trig
BEFORE INSERT ON ForumThread
FOR EACH ROW
BEGIN
  SELECT ThreadID_seq.nextval INTO :new.ThreadID FROM dual;
END;
/

-- for Post table
CREATE SEQUENCE PostID_Seq;
CREATE OR REPLACE TRIGGER PostID_trig
BEFORE INSERT ON Post
FOR EACH ROW
BEGIN
  SELECT PostID_seq.nextval INTO :new.PostID FROM dual;
END;
/

-- for Article table
CREATE SEQUENCE ArticleID_Seq;
CREATE OR REPLACE TRIGGER ArticleID_trig
BEFORE INSERT ON Article
FOR EACH ROW
BEGIN
  SELECT ArticleID_seq.nextval INTO :new.ArticleID FROM dual;
END;
/

-- creating triggers
/*update the column Karma in Users when a user gives karma to a post
karmaGiverKarma represents the karma held by the user who gave karma
karmaReceiver represents the user who posted the post that received karma
each user gets +1 karma from users who hold karma between 1 and 100,
+2 from users who hold karma between 101 and 200, +3 from users who hold karma between 201 and 300 and so on
*/
CREATE OR REPLACE TRIGGER Karma_trig
AFTER INSERT ON Karma
FOR EACH ROW
DECLARE
  karmaGiver VARCHAR(50);
  postReceivingKarma INTEGER;
  karmaGiverKarma INTEGER;
  karmaReceiver VARCHAR(50);
BEGIN
  karmaGiver := :new.UserName;
  postReceivingKarma := :new.PostID;
  SELECT Karma INTO karmaGiverKarma
    FROM Users WHERE UserName = karmaGiver;
  SELECT Username INTO karmaReceiver
    FROM Post WHERE PostID = postReceivingKarma;
  UPDATE Users SET Karma = Karma + TRUNC(karmaGiverKarma/100,0) + 1
    WHERE Username = karmaReceiver;
END;
/

/*update the column NumberOfPosts in Users when a user posts a new post
*/
CREATE OR REPLACE TRIGGER NumberOfPosts_trig
AFTER INSERT ON Post
FOR EACH ROW
DECLARE
  postingUser VARCHAR(50);
BEGIN
  postingUser := :new.UserName;
  UPDATE Users SET NumberOfPosts = NumberOfPosts + 1
    WHERE Username = postingUser;
END;
/

-- fill tables with content
INSERT INTO UserStatus VALUES('HSM Newbie');
INSERT INTO UserStatus VALUES('HSM Regular');
INSERT INTO UserStatus VALUES('HSM Addict');
INSERT INTO UserStatus VALUES('Moderator');

INSERT INTO Gender VALUES('Male');
INSERT INTO Gender VALUES('Female');

INSERT INTO TimeZone VALUES('(GMT+00:00) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London');
INSERT INTO TimeZone VALUES('(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna');
INSERT INTO TimeZone VALUES('(GMT+02:00) Athens, Bucharest, Istanbul');
INSERT INTO TimeZone VALUES('(GMT+03:00) Moscow, St. Petersburg, Volgograd');

INSERT INTO Users (UserName, JoinDate, Avatar, LastVisitDate, StatusDescription, Gender, TimeZone)
  VALUES('InsiderTrader', TO_DATE('2015/04/05','yyyy/mm/dd'), 'http://somesite.net/somepage/somepicture.jpg', TO_DATE('2015/04/10','yyyy/mm/dd'),
  'HSM Newbie', 'Male', '(GMT+00:00) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London');
INSERT INTO Users (UserName, JoinDate, Avatar, Karma, LastVisitDate, StatusDescription, Gender, TimeZone)
  VALUES('ForexForever', TO_DATE('2015/04/05','yyyy/mm/dd'), 'http://mysite.net/mypage/mypicture.jpg',
  467, TO_DATE('2015/05/23','yyyy/mm/dd'),
  'HSM Regular', 'Female', '(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna');
INSERT INTO Users (UserName, JoinDate, Avatar, LastVisitDate, StatusDescription, Gender, TimeZone)
  VALUES('GoldFinder', TO_DATE('2015/04/05','yyyy/mm/dd'), 'http://goldsite.net/goldpage/goldpicture.jpg', TO_DATE('2015/04/15','yyyy/mm/dd'),
  'HSM Addict', 'Male', '(GMT+02:00) Athens, Bucharest, Istanbul');
INSERT INTO Users (UserName, JoinDate, Avatar, Karma, LastVisitDate, StatusDescription, Gender, TimeZone)
  VALUES('SilverFox', TO_DATE('2015/04/05','yyyy/mm/dd'), 'http://silversite.net/silverpage/silverpicture.jpg',
  134, TO_DATE('2015/05/19','yyyy/mm/dd'),
  'Moderator', 'Male', '(GMT+03:00) Moscow, St. Petersburg, Volgograd');
  
INSERT INTO CommunityProfile (Username, UserLocation, WhatIDoForALiving, Interests, YearsInMarket)
  VALUES('ForexForever', 'Round on the outside and high in the middle', 'Estimator', 'Reading', 5);
INSERT INTO CommunityProfile (Username, UserLocation, WhatIDoForALiving, Interests, YearsInMarket, FavoriteQuote)
  VALUES('SilverFox', 'Neverland', 'Plumbing Contractor, Trader', 'Drumming, Mountainbiking, Surfing, Martial Arts', 8,
  'Sometimes one pays most for the things one gets for nothing.');
  
INSERT INTO AlbumCategory VALUES ('Charts');
INSERT INTO AlbumCategory VALUES ('Pictures');
INSERT INTO AlbumCategory VALUES ('Uncategorized');

INSERT INTO Album (AlbumName, CreationDate, AlbumDescription, UserName, AlbumCategory) VALUES
  ('My Charts', TO_DATE('2015/04/05','yyyy/mm/dd'), 'Charts about Gold and precious metals', 'GoldFinder', 'Charts');
INSERT INTO Album (AlbumName, CreationDate, AlbumDescription, UserName, AlbumCategory) VALUES
  ('My Pictures', TO_DATE('2015/04/05','yyyy/mm/dd'), 'My profile pictures', 'InsiderTrader', 'Pictures');
INSERT INTO Album (AlbumName, CreationDate, AlbumDescription, UserName,  AlbumCategory) VALUES
  ('Miscellaneous', TO_DATE('2015/04/05','yyyy/mm/dd'), 'Pictures about gold and other commodities', 'InsiderTrader', 'Uncategorized');
  
INSERT INTO Photo (PhotoLink, PhotoDescription, AlbumID) VALUES
  ('http://xyzsite.net/xyzpage/xyzpicture.jpg', 'Gold Chart 2015', 1);
INSERT INTO Photo (PhotoLink, PhotoDescription, AlbumID) VALUES
  ('http://commoditysite.net/commoditypage/commpicture.jpg', 'Commodity Chart 2015', 1);
INSERT INTO Photo (PhotoLink, PhotoDescription, AlbumID) VALUES
  ('http://hsmserver/Goldfinger/MeDog.jpg', 'Me and my dog', 2);
INSERT INTO Photo (PhotoLink, PhotoDescription, AlbumID) VALUES
  ('http://hsmserver/InsiderTrader/Cycling.jpg', 'Cycling', 2);
  
INSERT INTO Forum (Title, Description)
  VALUES ('Stock Message Boards NYSE, NASDAQ, AMEX', 'Message boards for stocks trading on major exchanges');
INSERT INTO Forum (Title, Description)
  VALUES ('Stock Market Today', 'The Stock Market Today forum. Welcome! Here are the guidelines:
  Post breaking news events that are moving the market, Intraday stock market chat goes into the weekly thread,
  Technical set ups and break outs, post them! No penny stocks.');

INSERT INTO ForumThread (Title, ThreadDate, Sticky, ThreadViews, UserName, ForumID)
  VALUES ('AAPL - Apple Inc', TO_DATE('2015/04/05','yyyy/mm/dd'), 1, 55, 'InsiderTrader', 1);
INSERT INTO ForumThread (Title, ThreadDate, ThreadViews, UserName, ForumID)
  VALUES ('Gold Futures and ETFs - GLD, DGL, GDX, IAU', TO_DATE('2015/04/05','yyyy/mm/dd'), 23, 'GoldFinder', 1);
INSERT INTO ForumThread (Title, ThreadDate, ThreadViews, UserName, ForumID)
  VALUES ('U.S. Dollar Index - .DXY ', TO_DATE('2015/04/05','yyyy/mm/dd'), 15, 'SilverFox', 2);

INSERT INTO Post (PostNumber, PostDate, PostContent, UserName, ThreadID)
  VALUES (1, TO_DATE('2015/04/05','yyyy/mm/dd'), 'Apple is announcing a capital increase', 'InsiderTrader', 1);
INSERT INTO Post (PostNumber, PostDate, PostContent, UserName, ThreadID)
  VALUES (2, TO_DATE('2015/04/07','yyyy/mm/dd'), 'I hope the price is going down', 'GoldFinder', 1);
INSERT INTO Post (PostNumber, PostDate, PostContent, UserName, ThreadID)
  VALUES (3, TO_DATE('2015/04/08','yyyy/mm/dd'),'I am glad I sold Apple shares at 80 USD', 'ForexForever', 1);
INSERT INTO Post (PostNumber, PostDate, PostContent, UserName, ThreadID)
  VALUES (1, TO_DATE('2015/04/05','yyyy/mm/dd'), 'Gold will break 900 soon and it is still at around half its inflation-adjusted high from 1980', 'GoldFinder', 2);
INSERT INTO Post (PostNumber, PostDate, PostContent, UserName, ThreadID)
  VALUES (2, TO_DATE('2015/04/07','yyyy/mm/dd'),'I like gold, not much though. I got it when it was at  USD 80.', 'InsiderTrader', 2);
INSERT INTO Post (PostNumber, PostDate, PostContent, UserName, ThreadID)
  VALUES (3, TO_DATE('2015/04/08','yyyy/mm/dd'),'This is a stupid thread', 'SilverFox', 2);

INSERT INTO ReportType VALUES ('Offensive');
INSERT INTO ReportType VALUES ('Spam');
INSERT INTO ReportType VALUES ('Other');

INSERT INTO ReportPost (Username, PostID, ReportPostDate, ReportType)
  VALUES ('InsiderTrader', 6, TO_DATE('2015/04/08','yyyy/mm/dd'), 'Offensive');
INSERT INTO ReportPost (Username, PostID, ReportPostDate, ReportType)
  VALUES ('SilverFox', 2, TO_DATE('2015/04/09','yyyy/mm/dd'), 'Spam');
  
INSERT INTO Karma (Username, PostID, KarmaDate, KarmaComment)
  VALUES ('GoldFinder', 1, TO_DATE('2015/04/09','yyyy/mm/dd'), 'Very useful');
INSERT INTO Karma (Username, PostID, KarmaDate, KarmaComment)
  VALUES ('SilverFox', 1, TO_DATE('2015/04/16','yyyy/mm/dd'), 'Thank you!');
INSERT INTO Karma (Username, PostID, KarmaDate)
  VALUES ('ForexForever', 1, TO_DATE('2015/04/19','yyyy/mm/dd'));
INSERT INTO Karma (Username, PostID, KarmaDate, KarmaComment)
  VALUES ('InsiderTrader', 4, TO_DATE('2015/04/10','yyyy/mm/dd'), 'Useful');
INSERT INTO Karma (Username, PostID, KarmaDate)
  VALUES ('ForexForever', 4, TO_DATE('2015/04/10','yyyy/mm/dd'));
  
INSERT INTO Quote (QuotingPost,  QuotedPost) VALUES (2, 1);
INSERT INTO Quote (QuotingPost,  QuotedPost) VALUES (3, 2);
INSERT INTO Quote (QuotingPost,  QuotedPost) VALUES (3, 1);
INSERT INTO Quote (QuotingPost,  QuotedPost) VALUES (6, 4);
INSERT INTO Quote (QuotingPost,  QuotedPost) VALUES (5, 4);

INSERT INTO Tag VALUES ('Gold');
INSERT INTO Tag VALUES ('Shares');
INSERT INTO Tag VALUES ('Apple');
INSERT INTO Tag VALUES ('Price');
INSERT INTO Tag VALUES ('ETF');
INSERT INTO Tag VALUES ('Index');

INSERT INTO ThreadTag VALUES (1, 'Shares');
INSERT INTO ThreadTag VALUES (1, 'Apple');
INSERT INTO ThreadTag VALUES (1, 'Price');
INSERT INTO ThreadTag VALUES (2, 'Gold');
INSERT INTO ThreadTag VALUES (2, 'ETF');
INSERT INTO ThreadTag VALUES (3, 'Index');

INSERT INTO Article (ArticleDate, ArticleTitle, ArticleContent, ArticleSummary, ArticleViews, UserName)
  VALUES (TO_DATE('2015/04/10','yyyy/mm/dd'), 'Gold: Not The Safe Haven', 'Central Banks buy and sell gold to maintain balance in their portfolio. Retail and institutions buy and sell gold for a variety of investment strategies. While I agree precious metals are great for a balanced portfolio.',
  'If a comet hits the earth, and civilization gets thrown back a peg or two, as infrastructure and society are being rebuilt, I will need seeds, clean water, food and survival gear, at which point gold (GLD) will just be some shiny yellow rocks.',
  10, 'GoldFinder');
INSERT INTO Article (ArticleDate, ArticleTitle, ArticleContent, ArticleSummary, ArticleViews, UserName)
  VALUES (TO_DATE('2015/04/11','yyyy/mm/dd'), 'SP And The Blow Off The Top', 'I feel no sympathy for the bears that have called for a long-term top every time the market prints new highs and then starts to correct. Unlike a broken clock that tells the correct time twice a day, they have not been right yet in four years. The broken clock, in this case, is correct twice a decade and it is true that the infamous "blow-off the top" is coming, but timing is everything in this game.',
  'I feel no sympathy for the bears that have called for a long-term top every time the market prints new highs and then starts to correct.',
  12, 'InsiderTrader');
  
INSERT INTO ArticleTag VALUES (1, 'Gold');
INSERT INTO ArticleTag VALUES (2, 'Index');
INSERT INTO ArticleTag VALUES (1, 'ETF');

INSERT INTO ArticleComment VALUES ('ForexForever', 1, TO_DATE('2015/04/12','yyyy/mm/dd'), 'Good review. I have different view though.');
INSERT INTO ArticleComment VALUES ('SilverFox', 2, TO_DATE('2015/04/14','yyyy/mm/dd'), 'Good review. I completely agree.');

INSERT INTO ReportArticle VALUES ('SilverFox', 1, TO_DATE('2015/04/13','yyyy/mm/dd'), 'Misleading article', 'Other');
INSERT INTO ReportArticle (UserName, ArticleID, ReportArticleDate, ReportType)
  VALUES ('InsiderTrader', 1, TO_DATE('2015/04/13','yyyy/mm/dd'), 'Spam');

