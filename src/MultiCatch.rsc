module MultiCatch

import lang::java::\syntax::Java18;
import ParseTree; 
import IO;
import Map;
import Type; 
import List;

/**
 * Refactor a try-catch statement to use the 
 * MultiCatch construct of Java 7. 
 */
public CompilationUnit refactorMultiCatch(CompilationUnit unit) =  visit(unit) {
  case (TryStatement)`try <Block b1> <Catches c1>` 
  =>   (TryStatement)`try <Block b1> <Catches mc>`
  when mc := computeMultiCatches(c1)
};

/*
 * Based on a simple notion of similarity, 
 * this function calculates the possible 
 * occurences of MultiCatch. 
 */ 
private Catches computeMultiCatches(cs){
   map [Block, tuple[list[CatchType], VariableDeclaratorId, Block] ] mCatches =();
   visit(cs){
      case(CatchClause)`catch (<CatchType t> <VariableDeclaratorId vId>) <Block b>` :{
         if (b in mCatches){
            <ts, vId, blk> = mCatches[b];
            ts += t;
            mCatches[b] = <ts, vId, blk>;
         }
         else{
            mCatches[b] = <[t], vId, b>;
         }
      }
   }
   print("size: ");
   println(size([mCatches[b] | b <- mCatches]));
   return generateMultiCatches([mCatches[b] | b <- mCatches]); 
}

/*
 * Creates a syntactic catch clause (either a simple one or 
 * a multicatch). 
 */
Catches generateMultiCatches([<ts, vId, b>]) = {
  types = parse(#CatchType, intercalate("| ", ts));
  return (Catches)`catch(<CatchType types>  <VariableDeclaratorId vId>) <Block b>`; 
};
Catches generateMultiCatches([<ts, vId, b>, C*]) = {
  catches = generateMultiCatches(C);
  types = parse(#CatchType, intercalate("| ", ts));
  return (Catches)`catch(<CatchType types> <VariableDeclaratorId vId>) <Block b> <CatchClause+ catches>`;
};

