import random
import csv

__lPerc = [10, 30, 50, 70, 90]
__lRef = ['MC', 'VA', 'SS']

#utilização import generatecsv
#generatecsv.generateCSV(<csvEntrada>, <csvSaida>)
def generateCSV(fInput, fOutput):
    writecsv(fOutput, readcsv(fInput))

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
