// Author: Payan Canaran <canaran@cshl.edu>
// Javascript for blast_blat page
// Copyright@2006 Cold Spring Harbor Laboratory
// $Id: search_form.js,v 1.1.1.1 2010-01-25 15:47:07 tharris Exp $

// Store dynamic options at load time
var blastAppClone          = makeCloneArray('blast_app');
// var processQueryParamClone = makeCloneArray('process_query_param');
var databaseClone          = makeCloneArray('database');

// Other Global Vars
var queryDetermineType     = 'toggle_switch'; // OR 'sequence_entry'

function updateAllOptions() {
    updateBlastAppOptions();
//     updateProcessQueryOptions();
    updateDatabaseOptions();

    updateMessage();

    return 1;
}   

function updateBlastAppOptions() {
    var paramValues = getParamValues();
    var queryType = paramValues[0];
    var appType   = paramValues[1];
    var queryApp  = paramValues[2];

    var copy = copyArray(blastAppClone);
    var blastApp = document.getElementById('blast_app');
    updateOneOption(copy, blastApp, queryType, 'query');

    return 1;
}   
    
// function updateProcessQueryOptions() {
//     var paramValues = getParamValues();
//     var queryType = paramValues[0];
//     var appType   = paramValues[1];
//     var queryApp  = paramValues[2];
// 
//     var copy = copyArray(processQueryParamClone);
//     var processQueryParam = document.getElementById('process_query_param');
// 
//     updateOneOption(copy, processQueryParam, queryType, 'query');
// 
//     return 1;
// }   

function updateDatabaseOptions() {
    var paramValues = getParamValues();
    var queryType = paramValues[0];
    var appType   = paramValues[1];
    var queryApp  = paramValues[2];

    var copy = copyArray(databaseClone);
    var database = document.getElementById('database');
    updateOneOption(copy, database, queryApp, 'query-app');

    if (!database.options.length) {
        var newOption = new Option('No database available', 'not_selected', 0, 0);
        newOption.selected = true;
        
        database.options[0] = newOption;
    }
    
    return 1;
}   

function updateOneOption(cloneArray, parentElement, optionCriterion, criterion) {
     var newOptions = [];

    // Determine selectedOption
    var selectedOption;
    for (var j = 0; j < parentElement.options.length; j++) {
        if (parentElement.options[j].selected) {
           selectedOption = parentElement.options[j].value;
        }
    }    

    // If an option is already selected, make sure it's selected as well on the clone
    for (var i = 0; i < cloneArray.length; i++) {
        if (cloneArray[i].value == selectedOption) {
            cloneArray[i].selected = true;
        }    
        
        else {
            cloneArray[i].selected = false;
        }    
    }
    
    // Add clone options into new options if they satisfy the criteria
    for (var i = 0; i < cloneArray.length; i++) {
        var expectedCriterion = cloneArray[i].getAttribute(criterion);

        var expectedCriterionMap = [];
        var expectedCriterionArray = expectedCriterion.split(" ");

        for (var j = 0; j < expectedCriterionArray.length; j++) {
            expectedCriterionMap[expectedCriterionArray[j]] = true;
        }    

        if (!optionCriterion 
            || expectedCriterionMap['all'] == true
            || expectedCriterionMap[optionCriterion]
            ) {
            var newOption = cloneArray[i];
            newOptions.push(newOption);
        }
    }

    // Clean options
    while (parentElement.options.length > 0) {
        parentElement.options[0] = null;
    }

    // Re-create options
    var numberOptionsSelected = 0;
    for (var i = 0; i < newOptions.length; i++) {
        parentElement.options[i] = newOptions[i];
        if (parentElement.options[i].selected) {
            numberOptionsSelected++;
        }    
    }

    // If no option is selected in the new options, select the first one
    if (!numberOptionsSelected && parentElement.options.length > 0) {
       parentElement.options[0].selected = true;
    }

    return 1;
}

function resetAllOptions() {
    var blastAppCopy          = copyArray(blastAppClone);
//    var processQueryParamCopy = copyArray(processQueryParamClone);
    var databaseCopy          = copyArray(databaseClone);

    var blastApp          = document.getElementById('blast_app');
//    var processQueryParam = document.getElementById('process_query_param');
    var database          = document.getElementById('database');
    
    var queryType;
    var appType;
    var queryApp;

    updateOneOption(blastAppCopy,          blastApp,          queryType, 'query');
//    updateOneOption(processQueryParamCopy, processQueryParam, queryType, 'query');
    updateOneOption(databaseCopy,          database,          queryApp,  'query-app');

    document.getElementById("message").innerHTML = "Please enter a query sequence ...";

    return 1;
}   

function updateMessage() {
    var sequence = document.getElementById('query_sequence').value;

    sequence = sequence.replace(/^>[^\n\r]*[\n\r]+/, '');
    sequence = sequence.replace(/[\n\r]/g,           '');
    sequence = sequence.replace(/\s+/g,              '');
    
    if (!sequence) {
        document.getElementById("message").innerHTML = "Please enter a query sequence ...";
    }    
    
    else if (sequence.length < 10) {
        document.getElementById("message").innerHTML = "At least 10 residues is required to perform a search!";
    }    
    
    else if (document.getElementById('database').options.length < 2) {
        document.getElementById("message").innerHTML = "No database is available for this query-application pair!";
    }    

    else {
        document.getElementById("message").innerHTML = "Please click submit to perform search ...";
    }    
    
    return 1;
}    
    

function getParamValues() {
    var querySequence = document.getElementById('query_sequence');
    var blastApp      = document.getElementById('blast_app');

    var queryType;

    if (queryDetermineType == 'sequence_entry') {
        queryType = typeSequence(querySequence.value);
    }     
    else if (document.getElementById('query_type_nucl').checked) {
        queryType = 'nucl';
    }    
    else if (document.getElementById('query_type_prot').checked) {
        queryType = 'prot';
    }    

    if (queryType == 'nucl') {
        document.getElementById('query_type_prot').checked = 0;
        document.getElementById('query_type_nucl').checked = 1;
    }    
    else {
        document.getElementById('query_type_prot').checked = 1;
        document.getElementById('query_type_nucl').checked = 0;
    }    
    
    var appType = "";
    var searchTypeBlast = document.getElementById('search_type_blast').checked;
    var searchTypeBlat  = document.getElementById('search_type_blat').checked;
    if (searchTypeBlast) {
        appType = blastApp.options[blastApp.selectedIndex].value;
    }
    else if (searchTypeBlat) {
        appType = "blat";
    }
    
    var queryApp = (queryType && appType) ? queryType + ":" + appType
                                        : null;
    return new Array(queryType, appType, queryApp);
}

function typeSequence(sequence) {
    var sequenceType = "";

    if (!sequence) {
        return sequenceType;
    }    

    sequence = sequence.replace(/^>[^\n\r]*[\n\r]+/, '');
    sequence = sequence.replace(/[\n\r]/g,           '');
    sequence = sequence.replace(/\s+/g,              '');
    sequence = sequence.toUpperCase();        

    var atcgContent = sequence.match(/[ATCG]/g);
    var atcgRatio = atcgContent ? atcgContent.length / sequence.length
                                : 0;
    
    sequenceType = atcgRatio > 0.97 ? "nucl" : "prot";

    return sequenceType;    
}
    


function makeCloneArray(id) {
    var cloneArray = [];
    var parentElement = document.getElementById(id);
    for (var i = 0; i < parentElement.options.length; i++) {
        var optionValue = parentElement.options[i].value;
        var optionText  = parentElement.options[i].text;
        var optionQuery = parentElement.options[i].getAttribute('query');
        var optionDb    = parentElement.options[i].getAttribute('db');
        var optionApp   = parentElement.options[i].getAttribute('query-app');

        var newOption = new Option(optionText, optionValue, 0, 0);
        newOption.setAttribute('query',     optionQuery);
        newOption.setAttribute('db',        optionDb);
        newOption.setAttribute('query-app', optionApp);

        cloneArray.push(newOption);
    }

    return cloneArray;
}    

function copyArray(array) {
    var copyArray = [];
//    var parentElement = document.getElementById(id);
    for (var i = 0; i < array.length; i++) {
        var optionValue = array[i].value;
        var optionText  = array[i].text;
        var optionQuery = array[i].getAttribute('query');
        var optionDb    = array[i].getAttribute('db');
        var optionApp   = array[i].getAttribute('query-app');

        var newOption = new Option(optionText, optionValue, 0, 0);
        newOption.setAttribute('query',     optionQuery);
        newOption.setAttribute('db',        optionDb);
        newOption.setAttribute('query-app', optionApp);

        copyArray.push(newOption);
    }

    return copyArray;
}    

// ------------------------------------------------
// 
//     addEvent function is an excerpt from:
//     
// 	DOMhelp 1.0
// 	written by Chris Heilmann
// 	http://www.wait-till-i.com
// 	To be featured in "Beginning JavaScript for Practical Web Development, Including  AJAX" 
// 

DOMhelp={
	addEvent: function(elm, evType, fn, useCapture){
		if (elm.addEventListener){
			elm.addEventListener(evType, fn, useCapture);
			return true;
		} else if (elm.attachEvent) {
			var r = elm.attachEvent('on' + evType, fn);
			return r;
		} else {
			elm['on' + evType] = fn;
		}
    }
};        

// 
// ------------------------------------------------

function debug(message) {
    document.getElementById("message2").innerHTML += message + "<br>";    
}    


function addSampleNucleotide() {
    document.getElementById('query_sequence').value = sampleNucleotide;
}    

function addSamplePeptide() {
    document.getElementById('query_sequence').value = samplePeptide;
}    

DOMhelp.addEvent(document.getElementById('query_sequence'),     'change', 
                 function(){queryDetermineType = 'sequence_entry'; updateAllOptions();},   false);

// Safari does not support onchange for radios, onclick needs to be used
DOMhelp.addEvent(document.getElementById('search_type_blast'),  'click',  updateAllOptions,    false);
DOMhelp.addEvent(document.getElementById('search_type_blat'),   'click',  updateAllOptions,    false);

DOMhelp.addEvent(document.getElementById('query_type_nucl'),    'click',
                 function(){queryDetermineType = 'toggle_switch'; updateAllOptions();},   false);
                 
DOMhelp.addEvent(document.getElementById('query_type_prot'),    'click',
                 function(){queryDetermineType = 'toggle_switch'; updateAllOptions();},   false);

DOMhelp.addEvent(document.getElementById('blast_app'),          'change', updateAllOptions,    false); 

// MS IE does not recognize change event on textarea if not done manually, using mouseout to supplement this
DOMhelp.addEvent(document.getElementById('sample_peptide'),     'click',
                 function(){addSamplePeptide(); queryDetermineType = 'sequence_entry'; updateAllOptions();},   false);

DOMhelp.addEvent(document.getElementById('sample_nucleotide'),  'click',
                 function(){addSampleNucleotide(); queryDetermineType = 'sequence_entry'; updateAllOptions();},   false);

DOMhelp.addEvent(document.forms[0], 'reset', resetAllOptions, false);


DOMhelp.addEvent(window, 'load',  updateAllOptions, false);

////////////////////////////////////

var sampleNucleotide = '>C37F5.1                   \n\
atgaatcacattgaccttttgaaggtcaaaaaagagccgccgtcgagttc \n\
ggaagaagccgaggaagaagaatctccgaaacatacgattgagggaattt \n\
tggatataagaaagaaagagatgaacgtctcagacttgatgtgtacccga \n\
tcctcgacacctccgacctcatcatccgtcgactcaatcataaccctgtg \n\
gcaattccttctagaactactgcaacaagaccaaaatggtgatataatcg \n\
aatggacacgcggaacggacggcgaattccgactgattgatgcagaagcc \n\
gtggcgagaaagtggggacaacggaaggcgaaaccgcatatgaattatga \n\
taaactgtcgagagcgttacgatattattatgagaagaatattattaaga \n\
aggtgatcggcaaaaagttcgtatatcgctttgtaactactgacgcccac \n\
gctccgccgaccgccgacttttcctcaaatatgaacatgaagatgtgtta \n\
tgtcaaagacgagaaggacattcgacacgagattccgtcgtttatgacgt \n\
cattacaagcaccgccgccgccgcctccaccacctcaaaatccacgtggc \n\
aacacggatttctcggcgctgagccttcttgggacggattcaccgacgac \n\
gcacagtgtcagcacaccaagtccaacagatagtgtgtgctccccgtcaa \n\
gcagtgtggcctcctcggcgactccatccacctcatcccctgtagatgag \n\
tcccgacaatgccgaaaacgatccctatcgccctccacgacgtcatcgac \n\
gactgcaccgccgccgccgccgcagccgccaacgaaaaaaggaatgaagc \n\
cgaacccgctgaacctgacagcaacctcgaatttctccttacaaccgtca \n\
atctcgtctccacttctgatgcttcagcaacaccatcaaaactccccgct \n\
attccaagcacagatcagtcaactgtacacgtacgcagcgctggcgtctg \n\
ccgggctttatggaccacaaatatcaccacatttggcgtcccagtcaccg \n\
ttccgatcaccactggtaacaccgaaaaatttggggctcggcgagcttgg \n\
cagcagtggtaggactcccggtcttggcgagagtcaggtgttccaattcc \n\
cgccggtctccgcattccaggccacaaatccgctgctaaacacattctcc \n\
aaccttatcagcccgatggccccgtttatgatgcccccatcacagtcgag \n\
tacctcgttcaagttcccatcgtcaacggattctttaaaaacacctacag \n\
tacccataaaaatgccaactttgtag';

var samplePeptide = '>WP:CE31440            \n\
MNHIDLLKVK KEPPSSSEEA EEEESPKHTI EGILDIRKKE \n\
MNVSDLMCTR SSTPPTSSSV DSIITLWQFL LELLQQDQNG \n\
DIIEWTRGTD GEFRLIDAEA VARKWGQRKA KPHMNYDKLS \n\
RALRYYYEKN IIKKVIGKKF VYRFVTTDAH APPTADFSSN \n\
MNMKMCYVKD EKDIRHEIPS FMTSLQAPPP PPPPPQNPRG \n\
NTDFSALSLL GTDSPTTHSV STPSPTDSVC SPSSSVASSA \n\
TPSTSSPVDE SRQCRKRSLS PSTTSSTTAP PPPPQPPTKK \n\
GMKPNPLNLT ATSNFSLQPS ISSPLLMLQQ HHQNSPLFQA \n\
QISQLYTYAA LASAGLYGPQ ISPHLASQSP FRSPLVTPKN \n\
LGLGELGSSG RTPGLGESQV FQFPPVSAFQ ATNPLLNTFS \n\
NLISPMAPFM MPPSQSSTSF KFPSSTDSLK TPTVPIKMPT \n\
L'; 

// DumperTagProperties["OPTION"] = ['text','value',];
// DumperAlert(parentElement.options);
