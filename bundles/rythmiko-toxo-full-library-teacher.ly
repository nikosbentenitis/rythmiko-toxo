\version "2.24.0"

\header {
  title = "Rythmiko Toxo — Full Library (Teacher)"
  tagline = ##f
}

#(define darbuka-style '(
  (dum default #f -1)
  (tek default #f 1)
  (ka default #f 2)
  (slap cross #f 0)
))

drumPitchNames.dum = #'dum
drumPitchNames.tek = #'tek
drumPitchNames.ka = #'ka
drumPitchNames.slap = #'slap

\paper {
  top-margin = 40
  bottom-margin = 30
  left-margin = 25
  right-margin = 25
  % force every single-bar system to fill the line width so the
  % proportional spacing inside is consistent across variations
  ragged-right = ##f
  ragged-last = ##f
  % keep content anchored near the top of each page instead of being
  % vertically stretched/centered when it doesn't fill the page
  ragged-bottom = ##t
  ragged-last-bottom = ##t
  % tighter vertical spacing between music staff and the TUBS markup below
  score-markup-spacing.basic-distance = #4
  score-markup-spacing.minimum-distance = #2
  score-markup-spacing.padding = #0.5
  % tighter spacing between adjacent markups (TUBS row + next-variation start)
  markup-markup-spacing.basic-distance = #2
  markup-markup-spacing.padding = #0.5
  markup-system-spacing.basic-distance = #4
  markup-system-spacing.padding = #0.5
  % extra space between the PDF title and the first rhythm
  top-markup-spacing.basic-distance = #14
  top-markup-spacing.padding = #4
  % Title should print only on the TOC (book's first page). LilyPond
  % otherwise prints the book/score title at the top of every bookpart's
  % first page. Blank both markups; the title is emitted explicitly as
  % markup before the TOC in book_body (see main()).
  bookTitleMarkup = \markup { }
  scoreTitleMarkup = \markup { }
}

\layout {
  \context {
    \Score
    % uniform-stretching makes note spacing strictly proportional to
    % duration, so the same time-position in every variation lands at the
    % same X coordinate across the page — i.e. the second dum (or any
    % other beat) lines up vertically across the stack of variations.
    \override SpacingSpanner.uniform-stretching = ##t
    \override SpacingSpanner.base-shortest-duration = #(ly:make-moment 1/4)
    \override SpacingSpanner.strict-note-spacing = ##t
    \override SpacingSpanner.spacing-increment = #3.0
    \override SpacingSpanner.shortest-duration-space = #1.5
    \override MetronomeMark.padding = #8
    \override RehearsalMark.extra-offset = #'(0 . 8)
    % Thin beat & half-beat bar lines
    \override BarLine.hair-thickness = #0.6
    \override BarLine.thick-thickness = #1.2
  }
  \context {
    \Staff
    \override StaffSymbol.staff-space = 7.5
  }
}

\paper {
  ragged-right = ##t
  ragged-last = ##t
  indent = 8\mm
  % Each variation is its own \score in ragged mode; tighten the gap
  % between consecutive scores so they sit close together.
  score-system-spacing.basic-distance = #6
  score-system-spacing.minimum-distance = #4
  score-system-spacing.padding = #1
  system-system-spacing.basic-distance = #6
  system-system-spacing.padding = #1
}
\layout {
  \context {
    \Score
    \override SpacingSpanner.uniform-stretching = ##f
    \override SpacingSpanner.strict-note-spacing = ##f
    \override SpacingSpanner.spacing-increment = #1.2
    \override SpacingSpanner.shortest-duration-space = #1.0
  }
}

% --- TUBS markup commands for boxes_per_beat = BOne ---
#(define-markup-command (tubsCellBOne layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-1.9250 . 1.9250) #'(-1.9250 . 1.9250)
             \translate #'(0 . -1.3475)
             \halign #CENTER \fontsize #-2 #text
           \translate #'(1.9250 . -1.9250)
             \override #'(thickness . 1.320)
             \draw-line #'(0 . 3.8500)
         }
       } #}))

#(define-markup-command (tubsCellThickBOne layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-1.9250 . 1.9250) #'(-1.9250 . 1.9250)
             \translate #'(0 . -1.3475)
             \halign #CENTER \fontsize #-2 #text
           \translate #'(1.9250 . -1.9250)
             \override #'(thickness . 3.300)
             \draw-line #'(0 . 3.8500)
         }
       } #}))

#(define-markup-command (tubsCellCircleBOne layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-1.9250 . 1.9250) #'(-1.9250 . 1.9250)
             \translate #'(0 . -1.3475)
             \halign #CENTER \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle \fontsize #-2 #text
           \translate #'(1.9250 . -1.9250)
             \override #'(thickness . 1.320)
             \draw-line #'(0 . 3.8500)
         }
       } #}))

#(define-markup-command (tubsCellCircleThickBOne layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-1.9250 . 1.9250) #'(-1.9250 . 1.9250)
             \translate #'(0 . -1.3475)
             \halign #CENTER \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle \fontsize #-2 #text
           \translate #'(1.9250 . -1.9250)
             \override #'(thickness . 3.300)
             \draw-line #'(0 . 3.8500)
         }
       } #}))

#(define-markup-command (countCellBOne layout props label)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-1.9250 . 1.9250) #'(-0.4000 . 0.4000)
             \translate #'(0 . -0.2800)
             \halign #CENTER \fontsize #-5 #label
           \translate #'(1.9250 . -0.4000)
             \transparent
             \override #'(thickness . 1.320)
             \draw-line #'(0 . 0.8000)
         }
       } #}))


% --- TUBS markup commands for boxes_per_beat = BTwo ---
#(define-markup-command (tubsCellBTwo layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-0.9625 . 0.9625) #'(-0.9625 . 0.9625)
             \translate #'(0 . -0.6738)
             \halign #CENTER \fontsize #-4 #text
           \translate #'(0.9625 . -0.9625)
             \override #'(thickness . 0.660)
             \draw-line #'(0 . 1.9250)
         }
       } #}))

#(define-markup-command (tubsCellThickBTwo layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-0.9625 . 0.9625) #'(-0.9625 . 0.9625)
             \translate #'(0 . -0.6738)
             \halign #CENTER \fontsize #-4 #text
           \translate #'(0.9625 . -0.9625)
             \override #'(thickness . 1.650)
             \draw-line #'(0 . 1.9250)
         }
       } #}))

#(define-markup-command (tubsCellCircleBTwo layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-0.9625 . 0.9625) #'(-0.9625 . 0.9625)
             \translate #'(0 . -0.6738)
             \halign #CENTER \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle \fontsize #-4 #text
           \translate #'(0.9625 . -0.9625)
             \override #'(thickness . 0.660)
             \draw-line #'(0 . 1.9250)
         }
       } #}))

#(define-markup-command (tubsCellCircleThickBTwo layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-0.9625 . 0.9625) #'(-0.9625 . 0.9625)
             \translate #'(0 . -0.6738)
             \halign #CENTER \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle \fontsize #-4 #text
           \translate #'(0.9625 . -0.9625)
             \override #'(thickness . 1.650)
             \draw-line #'(0 . 1.9250)
         }
       } #}))

#(define-markup-command (countCellBTwo layout props label)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-0.9625 . 0.9625) #'(-0.4000 . 0.4000)
             \translate #'(0 . -0.2800)
             \halign #CENTER \fontsize #-7 #label
           \translate #'(0.9625 . -0.4000)
             \transparent
             \override #'(thickness . 0.660)
             \draw-line #'(0 . 0.8000)
         }
       } #}))


% --- TUBS markup commands for boxes_per_beat = BFour ---
#(define-markup-command (tubsCellBFour layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-0.4813 . 0.4813) #'(-0.4813 . 0.4813)
             \translate #'(0 . -0.3369)
             \halign #CENTER \fontsize #-6 #text
           \translate #'(0.4813 . -0.4813)
             \override #'(thickness . 0.330)
             \draw-line #'(0 . 0.9625)
         }
       } #}))

#(define-markup-command (tubsCellThickBFour layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-0.4813 . 0.4813) #'(-0.4813 . 0.4813)
             \translate #'(0 . -0.3369)
             \halign #CENTER \fontsize #-6 #text
           \translate #'(0.4813 . -0.4813)
             \override #'(thickness . 0.825)
             \draw-line #'(0 . 0.9625)
         }
       } #}))

#(define-markup-command (tubsCellCircleBFour layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-0.4813 . 0.4813) #'(-0.4813 . 0.4813)
             \translate #'(0 . -0.3369)
             \halign #CENTER \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle \fontsize #-6 #text
           \translate #'(0.4813 . -0.4813)
             \override #'(thickness . 0.330)
             \draw-line #'(0 . 0.9625)
         }
       } #}))

#(define-markup-command (tubsCellCircleThickBFour layout props text)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-0.4813 . 0.4813) #'(-0.4813 . 0.4813)
             \translate #'(0 . -0.3369)
             \halign #CENTER \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle \fontsize #-6 #text
           \translate #'(0.4813 . -0.4813)
             \override #'(thickness . 0.825)
             \draw-line #'(0 . 0.9625)
         }
       } #}))

#(define-markup-command (countCellBFour layout props label)
  (string?)
  (interpret-markup layout props
    #{ \markup {
         \overlay {
           \with-dimensions #'(-0.4813 . 0.4813) #'(-0.4000 . 0.4000)
             \translate #'(0 . -0.2800)
             \halign #CENTER \fontsize #-9 #label
           \translate #'(0.4813 . -0.4000)
             \transparent
             \override #'(thickness . 0.330)
             \draw-line #'(0 . 0.8000)
         }
       } #}))

\book {
  \markup { \vspace #2 \fill-line { \fontsize #6 \bold "Rythmiko Toxo — Full Library (Teacher)" } }
  \markup { \vspace #1 }
  \markuplist \table-of-contents
  \pageBreak
\bookpart {
  \tocItem \markup "Απτάλικο"

\markup { \vspace #0.5 \bold \fontsize #3 "Απτάλικο" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "1"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 9/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek4_Δ^> tek4_Δ^> dum4_> tek8_Δ[ ka8_Α] dum4_> tek4_Δ^> dum4_> r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "2"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 9/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4 r4 r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "3"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 9/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4 r4 r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "4"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 9/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4 r4 r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "5"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 9/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4 r4 r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "6"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 9/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4 r4 r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}
}
\bookpart {
  \tocItem \markup "Azeri"

\markup { \vspace #0.5 \bold \fontsize #3 "Azeri" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "1"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek4_Δ tek4_Δ^>
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "2"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek8_Δ[ ka8_Α] tek8_Δ^>[ ka8_Α]
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "3"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_>[ tek16_Δ ka16_Α] tek4_Δ[ dum4_>]
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "4"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "5"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "6"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "7"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "8"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}
}
\bookpart {
  \tocItem \markup "Duyek"

\markup { \vspace #0.5 \bold \fontsize #3 "Duyek" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "1"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 4/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_>[ slap8_S] r8 slap8_S dum4_> slap4_S
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "2"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 4/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_>[ tek16_Δ ka16_Α] tek8_Δ[ ka8_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] dum16_>[ ka16_Α tek8_Δ] dum4_>
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "3"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 4/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_>[ tek16_Δ ka16_Α] r16 tek16_Δ[ ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] r16 slap16_S[ ka16_Α slap16_S ka16_Α] dum4_>
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "4"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "5"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "6"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "7"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "8"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}
}
\bookpart {
  \tocItem \markup "Εννιάσημος"

\markup { \vspace #0.5 \bold \fontsize #3 "Εννιάσημος" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "1"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 9/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek8_Δ^>[ tek8_Δ] dum4_> tek8_Δ^>[ tek8_Δ tek8_Δ]
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "2"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 9/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek8_Δ^>[ tek8_Δ] dum4_> tek8_Δ^>[ tek16_Δ ka16_Α tek16_Δ ka16_Α]
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "3"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 9/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_>[ tek16_Δ ka16_Α] tek8_Δ^>[ tek16_Δ ka16_Α] dum4_> tek8_Δ^>[ tek8_Δ tek8_Δ]
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "4"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 9/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_>[ tek16_Δ ka16_Α] tek8_Δ^>[ tek16_Δ ka16_Α] dum4_> tek8_Δ^>[ tek16_Δ ka16_Α tek16_Δ ka16_Α]
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "5"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 9/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_>[ tek16_Δ ka16_Α] tek8_Δ^>[ tek16_Δ ka16_Α] dum8_>[ tek16_Δ ka16_Α] tek8_Δ^>[ tek8_Δ tek8_Δ]
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "6"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 9/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8 r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "7"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 9/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8 r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "8"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 9/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8 r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "9"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 9/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8 r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "10"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 9/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8 r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}
}
\bookpart {
  \tocItem \markup "Μαντιλάτος"

\markup { \vspace #0.5 \bold \fontsize #3 "Μαντιλάτος" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "1"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 7/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek4_Δ tek4._Δ
      }
      { s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "2"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 7/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek8_Δ[ ka8_Α] tek8_Δ[ tek8_Δ ka8_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }]
      }
      { s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "3"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 7/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8 r8 r8
      }
      { s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "4"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 7/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8 r8 r8
      }
      { s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "5"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 7/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8 r8 r8
      }
      { s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "6"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 7/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8 r8 r8
      }
      { s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "7"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 7/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8 r8 r8
      }
      { s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "|" \noBreak s8 \bar "." }
    >>
}
}
\bookpart {
  \tocItem \markup "Semai"

\markup { \vspace #0.5 \bold \fontsize #3 "Semai" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "1"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek4_Δ tek4_Δ^>
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "2"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek8_Δ[ ka8_Α] tek8_Δ^>[ ka8_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }]
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "3"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek8_Δ[ ka8_Α] r8 ka8_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "4"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "5"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "6"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "7"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "8"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 3/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}
}
\bookpart {
  \tocItem \markup "Συρτοειδή"

\markup { \vspace #0.5 \bold \fontsize #3 "Συρτοειδή" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "1"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_>[ tek16_Δ ka16_Α] r16 ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }[ tek16_Δ ka16_Α]
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "2"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_>[ tek16_Δ ka16_Α] r16 ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }[ tek16_Δ^>] r16
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "3"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8._>[ ka16_Α] r16 ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }[ tek16_Δ^>] r16
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "4"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "5"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "6"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "7"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "8"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}
}
\bookpart {
  \tocItem \markup "Türk aksağı"

\markup { \vspace #0.5 \bold \fontsize #3 "Türk aksağı" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "1"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 5/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek4._Δ^>
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "2"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 5/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek8_Δ^>[ r8 tek8_Δ]
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "3"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 5/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_> tek8_Δ tek8_Δ^>[ tek8_Δ tek8_Δ]
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "4"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 5/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_>[ tek16_Δ ka16_Α] tek8_Δ[ tek16_Δ ka16_Α r16 ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }]
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "5"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 5/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "6"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 5/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "7"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 5/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "8"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 5/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "9"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 5/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}
}
\bookpart {
  \tocItem \markup "Sofyan"

\markup { \vspace #0.5 \bold \fontsize #3 "Sofyan" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "1"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8._>[ ka16_Α] tek8_Δ^>[ ka8_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }^>]
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "2"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> slap8_S[ slap8_S]
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "3"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_>[ tek16_Δ ka16_Α] r16 ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }[ tek16_Δ^>] r16
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "4"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8_>[ tek16_Δ ka16_Α] tek16_Δ[ ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" } tek8_Δ^>]
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "5"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum8._>[ ka16_Α] r16 ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }[ tek16_Δ^>] r16
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "6"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "7"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "8"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "9"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "10"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 4/8
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r8 r8 r8 r8
      }
      { s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
}
}
\bookpart {
  \tocItem \markup "Nim Sofyan"

\markup { \vspace #0.5 \bold \fontsize #3 "Nim Sofyan" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "1"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek8_Δ[ ka8_Α] dum4_> tek8_Δ[ ka8_Α]
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "2"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek8_Δ[ ka8_Α] dum4_>[ tek4_Δ^>]
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "3"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_>[ r8 ka8_Α] dum4_>[ tek4_Δ^>]
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "4"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "5"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "6"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "7"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "8"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}
}
\bookpart {
  \tocItem \markup "Kaşık Havası"

\markup { \vspace #0.5 \bold \fontsize #3 "Kaşık Havası" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "1"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> r4 dum4_> tek4_Δ^>
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "2"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek8_Δ^>[ ka8_Α^>] r4 tek4_Δ^>
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "3"
    }
    <<
      \drummode {
        \cadenzaOn   % manual bar-line control via the tick voice below
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Beam.damping = #0
        \override Beam.auto-knee-gap = #10000
        \override Beam.positions = #'(4 . 4)
        dum4_> tek8_Δ^>[ ka8_Α^>] r4 tek8_Δ^>[ ka8_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }^>]
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "4"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "5"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "6"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "7"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "8"
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #14
      \override VerticalAxisGroup.staff-staff-spacing.padding = #2
    }
    <<
      \drummode {
        \cadenzaOn
        \time 2/4
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r4 r4 r4 r4
      }
      { s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." s8 \bar "!" \noBreak s8 \bar "|" \noBreak s8 \bar "!" \noBreak s8 \bar "." }
    >>
}
}
\bookpart {
  \tocItem \markup "New Rhythms"

\markup { \vspace #0.5 \bold \fontsize #3 "New Rhythms" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "1"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
    }
    <<
      \drummode {
        \cadenzaOn
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r1 r1 r1 r1 r1 r1
        \bar "."
      }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "2"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
    }
    <<
      \drummode {
        \cadenzaOn
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r1 r1 r1 r1 r1 r1
        \bar "."
      }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "3"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
    }
    <<
      \drummode {
        \cadenzaOn
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r1 r1 r1 r1 r1 r1
        \bar "."
      }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "4"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
    }
    <<
      \drummode {
        \cadenzaOn
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r1 r1 r1 r1 r1 r1
        \bar "."
      }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "5"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
    }
    <<
      \drummode {
        \cadenzaOn
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r1 r1 r1 r1 r1 r1
        \bar "."
      }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "6"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
    }
    <<
      \drummode {
        \cadenzaOn
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r1 r1 r1 r1 r1 r1
        \bar "."
      }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "7"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
    }
    <<
      \drummode {
        \cadenzaOn
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r1 r1 r1 r1 r1 r1
        \bar "."
      }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "8"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
    }
    <<
      \drummode {
        \cadenzaOn
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r1 r1 r1 r1 r1 r1
        \bar "."
      }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "9"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
    }
    <<
      \drummode {
        \cadenzaOn
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r1 r1 r1 r1 r1 r1
        \bar "."
      }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #3
      drumStyleTable = #(alist->hash-table darbuka-style)
      instrumentName = "10"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
    }
    <<
      \drummode {
        \cadenzaOn
        \stemUp
        \autoBeamOff
        \override Rest.transparent = ##t
        r1 r1 r1 r1 r1 r1
        \bar "."
      }
    >>
}
}
}
