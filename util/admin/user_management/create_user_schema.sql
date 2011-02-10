CREATE TABLE auth_user ( userid char(32) NOT NULL,
                         username varchar(30) NOT NULL,
                         passwd varchar(30) NOT NULL default '',
                         PRIMARY KEY (userid),
                         UNIQUE username (username)
);

INSERT INTO auth_user VALUES ( '325684ec1b028eaf562dd484c5607a65', 'admin', 'qwe123' ); INSERT INTO auth_user VALUES ( 'ef19a80d627b5c48728d388c11900f3f', 'guest', 'guest' );

CREATE TABLE auth_ip ( network char(15) NOT NULL, 
                       netmask char(15) NOT NULL, 
                       userid char(32) NOT NULL, 
                       PRIMARY KEY (network, netmask)
);
