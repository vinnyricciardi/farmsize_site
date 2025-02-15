#!/bin/bash

#mv /Users/Vinny_Ricciardi/.jupyter/jupyter_nbconvert_config.json /Users/Vinny_Ricciardi/.jupyter/tmp_jupyter_nbconvert_config.json

# Generate the Slides and Pages
jupyter-nbconvert Notebooks/Index.ipynb --reveal-prefix=reveal.js
mv Notebooks/Index.html  index.html

cd Notebooks
arr=(*.ipynb)
cd ..
for f in "${arr[@]}"; do
   # Chop off the extension
   filename=$(basename "$f")
   extension="${filename##*.}"
   filename="${filename%.*}"

   # Convert the Notebook to HTML
   jupyter-nbconvert --to html Notebooks/"$filename".ipynb
   # Move to the Html directory
   mv Notebooks/"$filename".html  Html/"$filename".html

   # Copy all changes to pelican site
   p="/Users/Vinny_Ricciardi/Documents/Scripts/Python/Projects/Webpage_Research/site/content/projects/SDG23_global_baseline"
   cp Notebooks/"$filename".ipynb "$p"/"$filename".ipynb
   
   t=$(sed "s/_/ /g" <<< "$filename")
   d=$(date +%Y-%m-%d)

   txt=$(printf "Title: $t\nSlug: $filename\nDate: $d\nCategory: $filename\nTags: Data Harmonization, SDG 23\nAuthor: Vinny Ricciardi\nSummary:")
   printf "$txt" > "$p"/"$filename".ipynb-meta

   # Convert the Notebook to slides
   #jupyter-nbconvert --to slides Notebooks/"$filename".ipynb --reveal-prefix=reveal.js
   # Move to the Slides directory
   #mv Notebooks/"$filename".slides.html  Slides/"$filename".html

   # Convert the Notebook to Markdown
   #jupyter-nbconvert --to markdown Notebooks/"$filename".ipynb
   # Move to the Markdown directory
   #mv Notebooks/"$filename".md  Markdown/"$filename".md

   # Convert the Notebook to Latex
   #jupyter-nbconvert --to latex Notebooks/"$filename".ipynb
   # Move to the Tex directory
   #mv Notebooks/"$filename".tex  Tex/"$filename".tex

   # Convert the Notebook to Pdf
   #cp Notebooks/"$filename".ipynb src/"$filename".ipynb
   #cd src
   #jupyter-nbconvert --to pdf "$filename".ipynb
   # Move to the html directory
   #mv "$filename".pdf  ../Pdfs/"$filename".pdf
   #rm "$filename".ipynb
   #cd ..
done

cp Notebooks/pivottablejs.html Html/pivottablejs.html

# Push the updates to gh-pages
#mkdir -p /tmp/workspace
#cp -r * /tmp/workspace/
git add -A .
git commit -m "Update Slides"
git checkout -B gh-pages
git add -A .
git commit -m "Update Slides"
git push origin master gh-pages --force
git checkout master
#cp -r /tmp/workspace/* .
#rm -rf /tmp/workspace

#mv /Users/Vinny_Ricciardi/.jupyter/tmp_jupyter_nbconvert_config.json /Users/Vinny_Ricciardi/.jupyter/jupyter_nbconvert_config.json