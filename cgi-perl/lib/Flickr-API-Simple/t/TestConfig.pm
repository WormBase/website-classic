package TestConfig;

require Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/$api_key $app_secret $test_user $test_group/;

# Configuration variables for test

# PLEASE GET YOUR OWN KEYS AND SECRETS - THESE ARE ONLY FOR TESTING PURPOSES!
$api_key    = 'd05f0582d46a0b7ccd8a737e337a1c9c';
$app_secret = '849a95fd7949817a';

$test_user  = 'twharris';
$test_group = '23233534@N06';  # Just golden retrievers!

1;
