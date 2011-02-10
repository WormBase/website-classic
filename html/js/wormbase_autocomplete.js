/* 
 wormbase_autocomplete.js -- Yahoo autocomplete implementation

 Sheldon McKay <mckays@cshl.edu>
 $Id: wormbase_autocomplete.js,v 1.1.1.1 2010-01-25 15:47:08 tharris Exp $
*/

//////////////////////////////////////////////
// Turn off in unsupported browsers
// None are severely broken that I know of
var browserSupported = true;
//////////////////////////////////////////////

var autoCompleteIsOn=true, autoCompleteData,localURL,ajaxResult,overrideSkip;
var sessionURL = '/db/misc/session';

if (browserSupported) {
  var autoCompleteState = sessionParam('autoCompleteIsOn');

  if (autoCompleteState) {
    autoCompleteIsOn = autoCompleteState.match('ON') ? true : false;
  }
  else {
    sessionParam('autoCompleteIsOn','ON');
  }
}

var inactivePrompt = '\
  <input id="inactive" type="text" name="query" style="width:20em" autocomplete="on">';

function turnOffAutoComplete() {
  YAHOO.util.Dom.setStyle('autoCompleteContainer','display','none');
  autoCompleteIsOn = false;
  document.getElementById('enableAutoComplete').checked = false;

  autoCompletion();
}

function autoCompletion(el) {
  if (!browserSupported) {
    return false;
  }

  // toggle autocompletion if the call is made by the checkbox
  if (el && el.id == 'enableAutoComplete' && el.checked) {
    autoCompleteIsOn = true;
    sessionParam('autoCompleteIsOn','ON');
  }  
  else {
    autoCompleteIsOn = false;
    sessionParam('autoCompleteIsOn','OFF');
  }

  // This section will reload the page with autocompletion turned on.  
  // Currently, I just can't figure out how to restart autocompletion
  // without a page reload.  It will also save whatever text is in the
  // query box so that it can re restored after reload
  if (autoCompleteIsOn) {
     var currentPrompt = document.getElementById('autoCompleteInput')
       || document.getElementById('inactive');
     var currentInput = currentPrompt.value;
     window.location = '/';
  }
  
  // This section replaces the 'query' text field that triggers 
  // autocompletion with an inactive one that does not
  else {
    var currentInput = document.getElementById('autoCompleteInput').value;
    var wrapper = document.getElementById('autoCompleteSearch');
    wrapper.innerHTML = inactivePrompt;
    document.getElementById('inactive').value = currentInput;
  }

  setEnd(document.searchform.query);
}

function setEnd (el) {
  if (el.createTextRange) {
    var range = el.createTextRange();
    range.moveStart('character', el.value.length);
    range.collapse();
    range.select();
  }
}


// Enter key means they want to submit -- respect this
function skipAutoComplete (evt) {
  var kCode = (evt.which) ? evt.which : evt.keyCode

  // if the first control key we get is 'enter', submit
  // the form with no autocompletion
  if (kCode == 13 && !overrideSkip) { // the enter key
    document.searchform.submit();
  }
  else if ( ((kCode > 31) && (kCode < 41)) || kCode == 9 ) { //tab or arrow keys
    overrideSkip = true;	
    return true;
  }
  else if (kCode == 27) { //'esc' key
    overrideSkip = false;
    return true;
  }
}

function goAutoComplete() {
  if (!autoCompleteIsOn) {
    addCheckBox();
    return false;
  }

  var autoCompleteServer  = "/db/autocompleter2";
  var autoCompleteSchema  = ["\n","\t"];
  autoCompleteData  = new YAHOO.widget.DS_XHR(autoCompleteServer, autoCompleteSchema);
  autoCompleteData.responseType = YAHOO.widget.DS_XHR.TYPE_FLAT;
  autoCompleteData.flushCache();
  var autoComplete = new YAHOO.widget.AutoComplete("autoCompleteInput","autoCompleteContainer",autoCompleteData);
  autoComplete.allowBrowserAutocomplete = false;
  autoComplete.minQueryLength = 1;
  autoComplete.maxResultsDisplayed = 15;
  var searchClass = "class="+document.getElementById('class_search_menu').value;
  autoCompleteData.scriptQueryAppend = searchClass+";max="+autoComplete.maxResultsDisplayed;
  autoComplete.maxCacheEntries = 0;
  autoComplete.queryDelay = false;
  autoComplete.queryMatchCase = true;
  autoComplete.queryMatchSubset = false;
  autoComplete.animVert = false; 

  // Set the autocomplete contents header
  // sorry about the table layout but CSS is just
  // too spotty for cross-browser support in this case
  autoComplete.setHeader('\
  <table border=0 width=100% style="font-size:10pt">\
    <tr>\
      <td width:80% style="vertical-align:bottom">\
        Suggested Seaches\
      </td>\
      <td style="text-align:right">\
        <input type=checkbox name=turnoff onclick="turnOffAutoComplete(this)">disable\
      </td>\
    </tr>\
  </table>');

  // This interferes with user-override on form submit
  // best to leave it off, I'm afraid
  autoComplete.autoHighlight = false;

  // submit form right away after item is selected
  autoComplete.itemSelectEvent.subscribe(onItemSelect);

  autoComplete.formatResult = function(aResultItem, sQuery) {
     var sDisplay = aResultItem[0];
     var sNote    = aResultItem[1];
     return sDisplay ? sDisplay+' '+sNote : null;
  }

  // adjust the location of the container and make sure
  // there are no stray balloons open
  autoComplete.doBeforeExpandContainer = function() {
    hideAllTooltips();
    var sRegion = YAHOO.util.Dom.getRegion('autoCompleteSearch');
    YAHOO.util.Dom.setStyle('autoCompleteContainer','left',sRegion.left);
    YAHOO.util.Dom.setStyle('autoCompleteContainer','top',sRegion.bottom+2);
    return true;
  }

  addCheckBox();
}

// This function will launch the basic search script with optimized
// query terms but will trick YAHOO's autocomplete.js into
// updating the text box with the display term only
function onItemSelect(itemEvent,itemArray) {
  // get the hidden, optimized query behind the display text
  var itemData  = itemArray[2];
  var itemName  = itemData[3] || itemData[0];
  var itemClass = itemData[2];
  var params    = 'name='+itemName+';class='+itemClass;
  window.location = '/db/searches/basic?'+params;
}


function expiryDate(session) {
   var expires = new Date();

   // short-lived cookie for a session request
   if (session) {
   expires.setSeconds(expires.getSeconds()+30); 
   }
   else {
   expires.setDate(expires.getDate()+30);
   }
   return expires;
}

function setCookie( name, value, session ) {
  var expire = expiryDate(session);
  var myCookie = name + '=' + escape( value );
  myCookie = myCookie + ';expires=' + expire;
  document.cookie = myCookie;
}

function getCookie( name ) {
  var start = document.cookie.indexOf( name + '=' );
  var len = start + name.length + 1;
  if ( ( !start ) && ( name != document.cookie.substring( 0, name.length ) ) ) {
    return null;
  }
  if ( start == -1 ) {
    return null;
  }

  var end = document.cookie.indexOf( ';', len );
  if ( end == -1 ) {
    end = document.cookie.length;
  }

  return unescape( document.cookie.substring( len, end ) );
}

function addCheckBox() {
  var checkBox = document.getElementById('autoCompleteCheckbox');

  if (browserSupported) {
    document.getElementById('autoCompleteCheckbox').style.display = 'inline';
  }
  if (autoCompleteIsOn) {
    document.getElementById('enableAutoComplete').checked = true;
  }
}

function queryAppend(el) {
  var searchClass = el.value || el.selectedIndex.value;
  //var textBox = document.getElementById('autoCompleteInput');
  //textBox.value = '';

  if (searchClass && searchClass == 'Paper') {
    document.searchform.literature.checked=true;     
  } 
  else {              
    document.searchform.literature.checked=false;    
  }                     

  autoCompleteData.flushCache();
  autoCompleteData.scriptQueryAppend = 'class='+searchClass;
  sf();
}

// The AJAX session management widget
// This is a getter/setter
// As a setter (key, val), it will return true on success
// As a getter (key), it will return true or false for Boolean state queries
// The param will be deleted if the key is 'delete' and the value is the actual key

function sessionParam (key,value) {
  var postData;
  var url = sessionURL + '?';
  if (localURL) { url += 'URL='+localURL+';' }
  if (key && value) { url += key + '=' + value }
  else if (key) {
    url += 'query='+key;
  }
  else {
    alert('sessionParam() requires at least one argument');
  }
  
/*
   var aSynch = value == 'OFF' ? true : false; 

  var ajax  = new Ajax.Request( sessionURL,
                           { method:     'post',
                             asynchronous: aSynch, // important!
                             postBody:   postData ,
                             onSuccess: function(t) { updateResult(t.responseText) },
                             //onFailure: function(t) { alert('AJAX Failure! '+t.statusText)}
	                   });


  return ajaxResult || '';
*/


  var ajax;
  if (window.XMLHttpRequest) {
    ajax = new XMLHttpRequest();
  } else {
    ajax = new ActiveXObject("Microsoft.XMLHTTP");
  }

  if (ajax) {
     ajax.open("GET", url, false);
     ajax.send(null);
     return ajax.responseText || '';
  }
}



function updateResult (text) {
  ajaxResult = text;
}

// set class to 'gene' or 'literature' as required
function setClass (el,idx) {
  // reset to 'AnyGene' if we have unchecked 'literature search' 
  if (idx==11 && !el.checked) idx = 1;

  var menu = document.getElementById('class_search_menu');
  if (idx) {
    menu.selectedIndex=idx;
  }
  queryAppend(menu);    
}


