module MultiCatch

import lang::java::\syntax::Java18;
import ParseTree; 
import IO;
import Map;
import Type; 
import List;

public CompilationUnit refactorMultiCatch(CompilationUnit unit) =  visit(unit) {
  case (TryStatement)`try <Block b1> <Catches c1>` 
  =>   (TryStatement)`try <Block b1> <Catches mc>`
  when mc := computeMultiCatches(c1)
};

private Catches computeMultiCatches(cs){
   map [Block, tuple[list[CatchType], VariableDeclaratorId, Block] ] mCatches =();
   visit(cs){
      case(CatchClause)`catch (<CatchType t> <VariableDeclaratorId vId>) <Block b>` :{
         if (b  in mCatches){
            <ts, vId, blk> = mCatches[b];
            ts += t;
            mCatches[b] = <ts, vId, blk>;
         }
         else{
            mCatches[b] = <[t], vId, b>;
         }
      }
   }
   return generateMultiCatches([mCatches[b] | b <- mCatches]); 
}

Catches generateMultiCatches([<ts, vId, b>]) = {
  types = parse(#CatchType, intercalate("| ", ts));
  return (Catches)`catch(<CatchType types>  <VariableDeclaratorId vId>) <Block b>`; 
};
Catches generateMultiCatches([<ts, vId, b>, C*]) = {
  catches = generateMultiCatches(C*);
  types = parse(#CatchType, intercalate("|", ts));
  return (Catches)`catch(<CatchType types> <VariableDeclaratorId vId>) <Block b> <Catches catches>`;
};
