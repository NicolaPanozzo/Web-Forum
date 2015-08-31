DROP TRIGGER AlbumID_trig;
DROP SEQUENCE AlbumID_Seq;
/

DROP TRIGGER PhotoID_trig;
DROP SEQUENCE PhotoID_Seq;
/

DROP TRIGGER ForumID_trig;
DROP SEQUENCE ForumID_Seq;
/

DROP TRIGGER ThreadID_trig;
DROP SEQUENCE ThreadID_Seq;
/

DROP TRIGGER PostID_trig;
DROP SEQUENCE PostID_Seq;
/

DROP TRIGGER ArticleID_trig;
DROP SEQUENCE ArticleID_Seq;
/

DROP TRIGGER Karma_trig;
/

DROP TRIGGER NumberOfPosts_trig;
/

DROP TABLE ReportArticle;
/

DROP TABLE ArticleComment;
/

DROP TABLE ArticleTag;
/

DROP TABLE Article;
/

DROP TABLE ThreadTag;
/

DROP TABLE Tag;
/

DROP TABLE Quote;
/

DROP TABLE Karma;
/

DROP TABLE ReportPost;
/

DROP TABLE ReportType;
/

DROP TABLE Post;
/

DROP TABLE ForumThread;
/

DROP TABLE Forum;
/

DROP TABLE Photo;
/

DROP TABLE Album;
/

DROP TABLE AlbumCategory;
/

DROP TABLE CommunityProfile;
/

DROP TABLE Users;
/

DROP TABLE TimeZone;
/

DROP TABLE Gender;
/

DROP TABLE UserStatus;
/

PURGE RECYCLEBIN;
