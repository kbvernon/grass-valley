#let article(
  title: [],
  subtitle: none,
  authors: (),
  date: [],
  abstract: [],
  keywords: [],
  target_journal: [],
  correspondence: [],
  font: "libertinus serif",
  fontsize: 12pt,
  doc,
) = {
  set page(
    paper: "us-letter", 
    margin: (x: 1in, y: 1in)
  )
  set par(justify: false)
  set text(lang: "en",
           region: "US",
           font: font,
           size: fontsize)
  set heading(numbering: "1.1.")
  show heading.where(level: 1): it => block(it, below: 1.2em) 
  show heading.where(level: 2): it => block(it, below: 0.9em) 

  // title page
  text(size: 1.5em)[#title]
  if subtitle != none { 
    parbreak()
    text(size: 1.25em)[#subtitle] 
  }
  v(1em)  

  // authors
  let unique-affiliations = authors.map(a => { a.affiliation }).flatten().dedup()
  let affiliation-map = (:)
  for (i, aff) in unique-affiliations.enumerate() {
    affiliation-map.insert(aff, i + 1)
  }
  authors.map(author => {
    let author-affs = if type(author.affiliation) == array { author.affiliation } else { (author.affiliation,) }
    let aff-nums = author-affs.map(aff => str(affiliation-map.at(aff)))
    [#author.name#super[#aff-nums.join(",")]]
  }).join([, ])
  v(1em)

  // affiliations
  for (i, aff) in unique-affiliations.enumerate() {
    [#super[#(i + 1)] #text(size: 0.85em, style: "italic")[#aff]]
    linebreak()
  }
  v(1em)

  // date
  [*Last updated:* #date]
  v(1em)

  // abstract
  [*Abstract* #linebreak() #abstract]
  v(1em)

  // keywords
  [*Keywords:* #keywords]
  v(1em)

  // target journal
  [*Target Journal:* #target_journal]
  v(1em)

  // correspondence
  [*Correspondence:* #correspondence]
  pagebreak()

  set page(numbering: "1")
  counter(page).update(1)

  // main
  doc
}

#set table(
  inset: 6pt,
  stroke: none
)
