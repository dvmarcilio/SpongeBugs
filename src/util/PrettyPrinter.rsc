module util::PrettyPrinter

import DateTime;

//[toString(n) +
str prettyPrinterDuration(Duration dDur){
  list[str] lDur = ["anos", "meses", "dias", "horas", "minutos", "segundos", "milissegundos"];
  list[str] lRes = [];
  list[int] iDur = [i | int i <- dDur];
  return intercalate(", ",[toString(iDur[i]) + " " + lDur[i] | int i <- [0..7], dDur[i] != 0]);
}

real prettyPrinterDuration(Duration dDur, str sUnity) {
  if (sUnity == "ms"){
    list[real] factor = [0.0, 2592000000.0, 86400000.0 ,3600000.0 ,60000.0 ,1000.0 ,1.0];
    list[int] iDur = [i | int i <- dDur];
    return (0.0 | factor[i] * iDur[i] + it | int i <- [0..7]);
  }
  else if (sUnity == "s"){
    list[real] factor = [0.0 ,2592000.0 ,86400.0 ,3600.0 ,60.0 ,1.0 , 0.001];
    list[int] iDur = [i | int i <- dDur];
    return (0.0 | factor[i] * iDur[i] + it | int i <- [0..7]);
  }
  else if (sUnity == "min"){
    list[real] factor = [0.0 , 43200.0 ,1440.0 , 60.0, 1.0 , 1/60.0 , 1/60000.0];
    list[int] iDur = [i | int i <- dDur];
    return (0.0 | factor[i] * iDur[i] + it | int i <- [0..7]);
  } 
}
