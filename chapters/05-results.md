# Results

\begin{luacode}
  tex.print("\\begin{tabular}{lllllllll}")
    num=6
  for i=1,num do
    for j=1,num do
    ixj='$'..i..'\\times'..j..'='..i*j..'$';
    tex.print(ixj)
    if(j<num) then tex.sprint('&') else tex.sprint('\\\\') end
    end
  end
  tex.print("\\end{tabular}")
\end{luacode}
