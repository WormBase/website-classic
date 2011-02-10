/* Loader for wormbase javascript libraries
   Sheldon McKay <mckays@cshl.edu>
   $Id: wormbase.js,v 1.1.1.1 2010-01-25 15:47:07 tharris Exp $

   Please Use this script to load libraries and their dependencies
   as well as stylesheets
*/

// Global Stylesheet, etc
document.write('<link rel="stylesheet" href="/stylesheets/wormbase.css">');

// This stuff shouldn't be loaded for every page.
document.write('<link rel="alternate" type="application/atom+xml" title="Atom" href="http://www.wormbase.org/rss/wormbase-live-atom.xml" />');
document.write('<link rel="alternate" type="application/rss+xml" title="RSS 2.0" href="http://www.wormbase.org/rss/wormbase-live.xml" />');

// General utilities
document.write('<script type="text/javascript" src="/js/prototype.js"></script>');
document.write('<script type="text/javascript" src="/js/browserUA.js"></script>');
document.write('<script type="text/javascript" src="/js/yahoo/yahoo-dom-event.js"></script>');
document.write('<script type="text/javascript" src="/js/utils.js"></script>');


// autocompletion
document.write('<link rel="stylesheet" href="/stylesheets/autocomplete.css">');
document.write('<script type="text/javascript" src="/js/wormbase_autocomplete.js"></script>');
document.write('<script type="text/javascript" src="/js/yahoo/connection-min.js"></script>');
document.write('<script type="text/javascript" src="/js/yahoo/autocomplete-min.js"></script>');

// balloon tooltips
document.write('<script type="text/javascript" src="/js/balloon.js"></script>');
