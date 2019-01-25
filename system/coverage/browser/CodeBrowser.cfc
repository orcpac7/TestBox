/**
* ********************************************************************************
* Copyright Ortus Solutions, Corp
* www.ortussolutions.com
* ********************************************************************************
* I generate a code browser to see file-level coverage statistics
*/
component accessors=true {

	// Location of all assets in TestBox
	variables.ASSETS_DIR = expandPath( "/testbox/system/reports/assets" );

	/**
	 * Constructor
	 *
	 * @coverageTresholds Options for threshold
	 */
	function init( required struct coverageTresholds ) {
		variables.streamBuilder = new testbox.system.modules.cbStreams.models.StreamBuilder();
		variables.coverageTresholds = arguments.coverageTresholds;

		return this;
	}

	/**
	* @qryCoverageData A query object containing coverage data
	* @stats A struct of overview stats
	* @browserOutputDir Generation folder for code browser
	*/
	function generateBrowser(
		required query qryCoverageData,
		required struct stats,
		required string browserOutputDir
	) {

		// wipe old files
		if( directoryExists( browserOutputDir ) ) {
			try {
				directoryDelete( browserOutputDir, true );
			} catch ( Any e ) {
				// Windows can get cranky if explorer or something has a lock on a folder while you try to delete
				rethrow;
			}
		}

		// Create it fresh
		if( !directoryExists( browserOutputDir ) ) {
			directoryCreate( browserOutputDir );
			fileCopy( "#variables.ASSETS_DIR#/js/syntaxhighlighter.js", browserOutputDir );
			fileCopy( "#variables.ASSETS_DIR#/js/jquery-3.3.1.min.js", browserOutputDir );
			fileCopy( "#variables.ASSETS_DIR#/css/syntaxhighlighter.css", browserOutputDir );
			fileCopy( "#variables.ASSETS_DIR#/css/bootstrap.min.css", browserOutputDir );
		}

		// Create index
		savecontent variable="local.index" {
			include "templates/index.cfm";
		}
		fileWrite( browserOutputDir & '/index.html', local.index );

		// Create directory skeletons
		var dataStream = variables.streamBuilder
			.new()
			.rangeClosed( 1, qryCoverageData.recordcount )
			.map( function( index ){
				return qryCoverageData.getRow( index );
			} )
			.peek( function( item ){
				var theContainerDirectory = getDirectoryFromPath( "#browserOutputDir & item.relativeFilePath#" );

				if( !directoryExists( theContainerDirectory ) ){
					directoryCreate( theContainerDirectory );

					// TODO: I DON'T THINK THIS IS NECESSARY, INVESTIGATE
					fileCopy( "#variables.ASSETS_DIR#/js/syntaxhighlighter.js",   theContainerDirectory );
					fileCopy( "#variables.ASSETS_DIR#/js/bootstrap.min.js",       theContainerDirectory );
					fileCopy( "#variables.ASSETS_DIR#/js/jquery-3.3.1.min.js",    theContainerDirectory );
					fileCopy( "#variables.ASSETS_DIR#/js/popper.min.js",          theContainerDirectory );
					fileCopy( "#variables.ASSETS_DIR#/css/syntaxhighlighter.css", theContainerDirectory );
					fileCopy( "#variables.ASSETS_DIR#/css/bootstrap.min.css",     theContainerDirectory );
					fileCopy( "#variables.ASSETS_DIR#/css/fontawesome.css",       theContainerDirectory );
				}
			} )
			.toArray();

		// Created individual files now that skeleton is online
		variables.streamBuilder
			.new( dataStream )
			.parallel()
			.forEach( function( fileData ){
				// Coverage files are named after "real" files
				var theFile = "#browserOutputDir & fileData.relativeFilePath#.html";

				var lineNumbersBGColors = fileData.lineData.map( function( key, value ){
					return ( value > 0 ) ? "success" : "danger";
				} );
				var percentage              = round( fileData.percCoverage * 100 );
				var lineNumbersBGColorsJSON = SerializeJSON( lineNumbersBGColors );
				var fileContents            = fileRead( fileData.filePath );

				savecontent variable="local.fileTemplate" {
					include "templates/file.cfm";
				}

				fileWrite( theFile, local.fileTemplate );
			} );
	}

	/**
	 * visually reward or shame the user
	 * TODO: add more variations of color
	 *
	 * @percentage The percentage to get a color on
	 */
	function percentToContextualClass( required percentage ) {
		percentage = percentage;
		if( percentage > variables.coverageTresholds.bad && percentage < variables.coverageTresholds.good ) {
			return 'warning';
		} else if( percentage >= variables.coverageTresholds.good ) {
			return 'success';
		} else if( percentage <= variables.coverageTresholds.bad ) {
			return 'danger';
		}
	}

}