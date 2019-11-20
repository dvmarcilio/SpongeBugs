module lang::java::refactoring::sonar::LogUtils

import IO;
import Map;
import String;

public void writeLog(loc fileLoc, loc logPath, 
	str detailedLogFileName, str countLogFileName, 
	map[str, int] timesReplacedByScope) {
	
	if(!exists(logPath))
		mkDirectory(logPath);
	
	filePathStr = fileLoc.authority + fileLoc.path;
		
	detailedLogMap = createDetailedLogMap(filePathStr, timesReplacedByScope);
	detailedFilePath = logPath + detailedLogFileName;
	writeToLogFile(detailedLogMap, detailedFilePath);
	
	countFilePath = logPath + countLogFileName;
	writeToCountLogFile(filePathStr, countFilePath, timesReplacedByScope);
}

private map[str, list[str]] createDetailedLogMap(str filePathStr, map[str, int] timesReplacedByScope) {
	map[str, list[str]] logMap = ();
	logMap[filePathStr] = [];
	
	for (scope <- domain(timesReplacedByScope)) {
		timesReplaced = timesReplacedByScope[scope];
		logMap[filePathStr] += "Replaced <timesReplaced> in <trim(scope)>";
	}
	
	return logMap;
}

private void writeToLogFile(map[str, list[str]] detailedLogMap, loc filePath) {
	mapStr = toString(detailedLogMap);
	if (exists(filePath))
		appendToFile(filePath, "\n" + mapStr);
	else
		writeFile(filePath, mapStr);
}

private void writeToCountLogFile(str filePathStr, loc countFilePath, map[str, int] timesReplacedByScope) {
	timesReplaced = 0;
	for (scope <- domain(timesReplacedByScope)) {
		timesReplaced += timesReplacedByScope[scope];
	}
	
	countStr = "<filePathStr>: <timesReplaced>";
	
	writeToLogFile(countStr, countFilePath);
} 

private void writeToLogFile(str countStr, loc fileLoc) {
	if (exists(fileLoc))
		appendToFile(fileLoc, "\n" + countStr);
	else
		writeFile(fileLoc, countStr);
}