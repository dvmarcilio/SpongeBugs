#!/usr/bin/python
import sys, getopt, random, csv

__lPerc = [10, 30, 50, 70, 90]
__lRef = ['MC', 'VA', 'SS']

def main(argv):
   inputfile = ''
   outputfile = ''
   try:
      opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
   except getopt.GetoptError:
      print 'test.py -i <inputfile> -o <outputfile>'
      sys.exit(2)
   for opt, arg in opts:
      if opt in ("-h", "--help"):
         print ' ++usage: test.py -i <inputfile> -o <outputfile> \n ++if -o is omitted, <inputFile> will be updated'
         sys.exit()
      elif opt in ("-i", "--ifile"):
         inputfile = arg
         outputfile = arg if outputfile == '' else outputfile
      elif opt in ("-o", "--ofile"):
         outputfile = arg
      else:
         print 'invalid parameters! \nUse -h for help'
   if inputfile != '' and outputfile != '':
      __generateCSV(inputfile, outputfile)
      print ' ++', outputfile, 'generated with success!' if inputfile != outputfile else 'updated with success!'

def __generateCSV(fInput, fOutput):
    __writecsv(fOutput, __readcsv(fInput))

def __getRand(x):
    return random.randint(0, x)

def __getPercent():
    return __lPerc[__getRand(len(__lPerc) - 1)]

def __getRef():
    return __lRef[__getRand(len(__lRef) - 1)]

def __readcsv(fileIn):
    with open(fileIn, 'rb') as fRead:
        csvin = csv.reader(fRead)
        return [[row[0], row[1], __getRef(), __getPercent(), row[2]] for row in csvin]

def __writecsv(fileOut, content):
    with open(fileOut, 'wb') as f:
        writer = csv.writer(f)
        writer.writerows(content)

if __name__ == "__main__":
   main(sys.argv[1:])
