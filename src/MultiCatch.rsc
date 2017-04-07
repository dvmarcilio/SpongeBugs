module MultiCatch

import lang::java::\syntax::Java18;
import ParseTree; 
import IO;
import Map;
import Type; 
import List;

CompilationUnit refactorMultiCatch(CompilationUnit unit) =  visit(unit) {
  case (TryStatement)`try <Block b1> <Catches c1>` 
  =>   (TryStatement)`try <Block b1> <Catches mc>`
  when mc := buildMC(c1)
};

Catches buildMC(cs){
   map [Block, tuple[ list[CatchType], VariableDeclaratorId, Block] ] mCatches =();
   bool verifier = false;
   visit(cs){
      case(CatchClause)`catch (<CatchType t> <VariableDeclaratorId vId>) <Block b>` :{
         if (b  in mCatches){
            <ts, vId, blk> = mCatches[b];
            ts += t;
            mCatches[b] = <ts, vId, blk>;
            verifier = true; 
         }
         else{
            mCatches[b] = <[t], vId, b>;
         }
      }
   }
   if (verifier){
      println("****");
      list[str] res;
      res = ["catch (" + intercalate("|", mCatches[c][0]) + " " + mCatches[c][1] + ")" + c | c <- mCatches];
      //println(res);   
   } 
   return cs;
}
