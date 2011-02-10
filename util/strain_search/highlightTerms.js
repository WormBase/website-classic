
/*
 * This is the function that actually highlights a text string by
 * adding HTML tags before and after all occurrences of the search
 * term. You can pass your own tags if you'd like, or if the
 * highlightStartTag or highlightEndTag parameters are omitted or
 * are empty strings then the default <font> tags will be used.
 */
function doHighlight(bodyText, searchTerm, highlightStartTag, highlightEndTag) 
{
  // the highlightStartTag and highlightEndTag parameters are optional
  if ((!highlightStartTag) || (!highlightEndTag)) {
//    highlightStartTag = "<font style='color:blue; background-color:yellow;'>";
    highlightStartTag = "<font style='color:#933794; background-color:#cccccc;'>";	
    highlightEndTag = "</font>";
  }
  
  // find all occurences of the search term in the given text,
  // and add some "highlight" tags to them (we're not using a
  // regular expression search, because we want to filter out
  // matches that occur within HTML tags and script blocks, so
  // we have to do a little extra validation)
  var newText = "";
  var i = -1;
  var lcSearchTerm = searchTerm.toLowerCase();
  var lcBodyText = bodyText.toLowerCase();
    
  while (bodyText.length > 0) {
    i = lcBodyText.indexOf(lcSearchTerm, i+1);
    if (i < 0) {
      newText += bodyText;
      bodyText = "";
    } else {
      // skip anything inside an HTML tag
      if (bodyText.lastIndexOf(">", i) >= bodyText.lastIndexOf("<", i)) {
        // skip anything inside a <script> block
        if (lcBodyText.lastIndexOf("/script>", i) >= lcBodyText.lastIndexOf("<script", i)) {
          newText += bodyText.substring(0, i) + highlightStartTag + bodyText.substr(i, searchTerm.length) + highlightEndTag;
          bodyText = bodyText.substr(i + searchTerm.length);
          lcBodyText = bodyText.toLowerCase();
          i = -1;
        }
      }
    }
  }
  
  return newText;
}


/*
 * This is a modification of doHighlight that requires that characters surrounding searchTerm
 * must not be word characters \w ( [0-9a-zA-Z_])
 */
function doHighlightExact(bodyText, searchTerm, highlightStartTag, highlightEndTag) 
{
  // the highlightStartTag and highlightEndTag parameters are optional
  if ((!highlightStartTag) || (!highlightEndTag)) {
//    highlightStartTag = "<font style='color:blue; background-color:yellow;'>";
//    highlightStartTag = "<font style='color:#933794; background-color:#cccccc;'>";	
      highlightStartTag = "<font style='color:red;'>";

    highlightEndTag = "</font>";
  }
  
  // find all occurences of the search term in the given text,
  // and add some "highlight" tags to them (we're not using a
  // regular expression search, because we want to filter out
  // matches that occur within HTML tags and script blocks, so
  // we have to do a little extra validation)
  var newText = "";
  var i = -1;
  var lcSearchTerm = searchTerm.toLowerCase();
  var lcBodyText = bodyText.toLowerCase();
  var tmpBefore = "";
  var tmpAfter = "";	
    
  while (bodyText.length > 0) {
    i = lcBodyText.indexOf(lcSearchTerm, i+1);
    if (i < 0) {
      newText += bodyText;
      bodyText = "";
    } else {
      // skip anything inside an HTML tag
      if (bodyText.lastIndexOf(">", i) >= bodyText.lastIndexOf("<", i)) {
        // skip anything inside a <script> block
        if (lcBodyText.lastIndexOf("/script>", i) >= lcBodyText.lastIndexOf("<script", i)) {
	  // skip if sorrounding characters are \w
	  tmpBefore = lcBodyText.substring(i-1, i);
	  tmpAfter = lcBodyText.substring(i+searchTerm.length, 1+i+searchTerm.length);
	  if (tmpBefore.search(/\w+/) == -1 && tmpAfter.search(/\w+/) == -1) {
          	newText += bodyText.substring(0, i) + highlightStartTag + bodyText.substr(i, searchTerm.length) + highlightEndTag;
          	bodyText = bodyText.substr(i + searchTerm.length);
          	lcBodyText = bodyText.toLowerCase();
          	i = -1;
	  }
        }
      }
    }
  }
  
  return newText;
}





/*
 * This is sort of a wrapper function to the doHighlight function.
 * It takes the searchText that you pass, optionally splits it into
 * separate words, and transforms the text on the current web page.
 * Only the "searchText" parameter is required; all other parameters
 * are optional and can be omitted.
 */
function highlightSearchTerms(searchText, treatAsPhrase, warnOnFailure, highlightStartTag, highlightEndTag)
{
  // if the treatAsPhrase parameter is true, then we should search for 
  // the entire phrase that was entered; otherwise, we will split the
  // search string so that each word is searched for and highlighted
  // individually
  if (treatAsPhrase) {
    searchArray = [searchText];
  } else {
    searchArray = searchText.split(" ");
  }
  
  if (!document.body || typeof(document.body.innerHTML) == "undefined") {
    if (warnOnFailure) {
      alert("Sorry, for some reason the text of this page is unavailable. Searching will not work.");
    }
    return false;
  }
  
  var bodyText = document.body.innerHTML;
  for (var i = 0; i < searchArray.length; i++) {
//    bodyText = doHighlight(bodyText, searchArray[i], highlightStartTag, highlightEndTag);
      bodyText = doHighlightExact(bodyText, searchArray[i], highlightStartTag, highlightEndTag);
  }

//if (bodyText != document.body.innerHTML) {
//	alert("matches found!");
//	bodyText="Remove Highlighting "+bodyText;
//}	  

  document.body.innerHTML = bodyText;
  return true;
}




function highlightIgorSearchTerms(referrer)
{
  // This function has only been very lightly tested against
  // typical Google search URLs. If you wanted the Google search
  // terms to be automatically highlighted on a page, you could
  // call the function in the onload event of your <body> tag, 
  // like this:
  //   <body onload='highlightIgorSearchTerms(document.referrer);'>

//  var browser=navigator.appName;
//  if (browser=="Microsoft Internet Explorer") {
//	return false;
//  }

//  var browser=navigator.appName;
//  if (browser=="Microsoft Internet Explorer") {
//	alert(referrer);
//}

  var referrer = document.referrer;
  if (!referrer) {
    return false;
  }


  var queryPrefix = "query=";
  var startPos = referrer.toLowerCase().indexOf(queryPrefix);
  if ((startPos < 0) || (startPos + queryPrefix.length == referrer.length)) {
    return false;
  }
  
  var endPos = referrer.indexOf(";", startPos);
  if (endPos < 0) {
    endPos = referrer.length;
  }
  
  var queryString = referrer.substring(startPos + queryPrefix.length, endPos);
  // fix the space characters
  queryString = queryString.replace(/%20/gi, " ");
  queryString = queryString.replace(/\+/gi, " ");

  var exactPhrase = false;
  if (queryString.search(/\"/) != -1 || queryString.search(/%22/) != -1) {
     exactPhrase = true;
  }	

  // remove the quotes (if you're really creative, you could search for the
  // terms within the quotes as phrases, and everything else as single terms)
  queryString = queryString.replace(/%22/gi, "");
  queryString = queryString.replace(/\"/gi, "");

  queryString = queryString.replace(/%28/gi, "");
  queryString = queryString.replace(/\(/gi, "");	
  queryString = queryString.replace(/%29/gi, "");
  queryString = queryString.replace(/\)/gi, "");	

  queryString = queryString.replace(/\s+AND\s+/gi, " ");
  queryString = queryString.replace(/\s+OR\s+/gi, " ");
  queryString = queryString.replace(/\s+NOT\s+/gi, " ");

//  alert(queryString);		

  return highlightSearchTerms(queryString, exactPhrase);
}





