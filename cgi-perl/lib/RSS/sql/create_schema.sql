#create database object_history;


DROP TABLE IF EXISTS `objects`;
CREATE TABLE `objects` (
  `oid` int(11) NOT NULL auto_increment,
  `name` char(35) NOT NULL default '',
  `class` char(35) default '',
  `signature` char(32) NOT NULL default '',
  `last_modification_date` date default '2007-01-01',
  `ace_version` char(5) NOT NULL,
  PRIMARY KEY  (`oid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `history`;
CREATE TABLE `history` (
  `sid` int(11) NOT NULL auto_increment,
  `oid` int(11) NOT NULL,
  `version` char(5) default '',
  `date` date,
  `signature` char(32) NOT NULL default '',
  `notes` text default '',
  PRIMARY KEY  (`sid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

#DROP TABLE IF EXISTS `db_history`;
#CREATE TABLE `history` (
#  `sid` int(11) NOT NULL auto_increment,
#  `oid` int(11) NOT NULL,
#  `version` char(5) default '',
#  `date` date,
#  `signature` char(32) NOT NULL default '',
#  `notes` text default '',
#  PRIMARY KEY  (`sid`)
#) ENGINE=MyISAM DEFAULT CHARSET=latin1;
