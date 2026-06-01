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

% Teacher 2-line staff: dum + slap share the lower line; tek + ka share
% the upper line. The Greek letter markup under each note still tells the
% reader which stroke it is. Lines themselves are rendered transparent
% in render_staff for teacher mode (StaffSymbol.transparent = ##t), so
% only the noteheads + beams + Greek labels remain on the page.
% Positions ±1 keep dum/slap and tek/ka close enough that beam groups
% read as one rhythm but distinct enough to be readable.
#(define darbuka-style-teacher '(
  (dum default #f -1)
  (slap cross #f -1)
  (tek default #f 1)
  (ka default #f 1)
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
  % Roomy gap between scores so the Greek letter labels under each note
  % don't crash into the staff of the next variation, and so variations
  % feel like distinct lines rather than one tight column.
  score-system-spacing.basic-distance = #14
  score-system-spacing.minimum-distance = #10
  score-system-spacing.padding = #3
  system-system-spacing.basic-distance = #14
  system-system-spacing.padding = #3
}
\layout {
  \context {
    \Score
    \override SpacingSpanner.uniform-stretching = ##f
    \override SpacingSpanner.strict-note-spacing = ##f
    % Generous note-to-note spacing so the teacher edition reads as
    % spacious instead of crammed. shortest-duration-space sets the
    % minimum room each shortest note gets; spacing-increment scales
    % up from there for longer durations.
    \override SpacingSpanner.spacing-increment = #2.1
    \override SpacingSpanner.shortest-duration-space = #2.5
    \override SpacingSpanner.base-shortest-duration = #(ly:make-moment 1/8)
    % Hide the system-start bracket at the left edge of every staff
    % (the two thin vertical lines LilyPond draws by default) — it's
    % redundant once the staff lines themselves are also transparent.
    \override SystemStartBar.transparent = ##t
    % Interior bar lines (between bars in multi-bar variations) get a
    % fixed vertical extent so the line is the same height for every
    % rhythm. The range -4 to 4 spans 8 staff-spaces — twice the
    % previous height — and stays centered at the staff midpoint.
    % minimum-X-extent forces breathing room on both sides so the bar
    % sits midway between the last note of bar 1 and the first note of
    % bar 2 instead of crowding either one.
    \override BarLine.bar-extent = #'(-8 . 8)
    \override BarLine.minimum-X-extent = #'(-4 . 4)
    \override BarLine.space-alist =
      #'((time-signature extra-space . 2.0)
         (custos minimum-space . 2.0)
         (clef minimum-space . 2.0)
         (key-signature extra-space . 1.0)
         (key-cancellation extra-space . 1.0)
         (first-note fixed-space . 4.0)
         (next-note semi-fixed-space . 4.0)
         (right-edge extra-space . 1.0))
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
\markup { \vspace #3 }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = ""
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 }
    >>
}
}
\bookpart {
  \tocItem \markup "Μαντιλάτος"

\markup { \vspace #0.5 \bold \fontsize #3 "Μαντιλάτος" }
\markup { \vspace #3 }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "1"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "2"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 }
    >>
}
}
\bookpart {
  \tocItem \markup "Semai"

\markup { \vspace #0.5 \bold \fontsize #3 "Semai" }
\markup { \vspace #3 }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "1"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "2"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "3"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 \noBreak s8 }
    >>
}
}
\bookpart {
  \tocItem \markup "Συρτοειδή"

\markup { \vspace #0.5 \bold \fontsize #3 "Συρτοειδή" }
\markup { \vspace #3 }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "1"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "2"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "3"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}
}
\bookpart {
  \tocItem \markup "Sofyan"

\markup { \vspace #0.5 \bold \fontsize #3 "Sofyan" }
\markup { \vspace #3 }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "1"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "2"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "3"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "4"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "5"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}
}
\bookpart {
  \tocItem \markup "Nim Sofyan"

\markup { \vspace #0.5 \bold \fontsize #3 "Nim Sofyan" }
\markup { \vspace #3 }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "1"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_> tek16_Δ[ ka16_Α] dum8_> tek16_Δ[ ka16_Α]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "2"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_> tek16_Δ[ ka16_Α] dum8_>[ tek8_Δ^>]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "3"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8._>[ ka16_Α] dum8_>[ tek8_Δ^>]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}
}
\bookpart {
  \tocItem \markup "Kaşık Havası"

\markup { \vspace #0.5 \bold \fontsize #3 "Kaşık Havası" }
\markup { \vspace #3 }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "1"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s8 \noBreak s8 \noBreak s8 \noBreak s8 \bar "." s8 \noBreak s8 \noBreak s8 \noBreak s8 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "2"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s8 \noBreak s8 \noBreak s8 \noBreak s8 \bar "." s8 \noBreak s8 \noBreak s8 \noBreak s8 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "3"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s8 \noBreak s8 \noBreak s8 \noBreak s8 \bar "." s8 \noBreak s8 \noBreak s8 \noBreak s8 }
    >>
}
}
\bookpart {
  \tocItem \markup "Azeri"

\markup { \vspace #0.5 \bold \fontsize #3 "Azeri" }
\markup { \vspace #3 }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "1"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "2"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "3"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "4"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ ka16_Α ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] slap8_S[ slap8_S] slap4_S
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "5"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ ka16_Α ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] slap8_S[ slap8_S] slap8_S[ ka16_Α ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}
}
\bookpart {
  \tocItem \markup "Duyek"

\markup { \vspace #0.5 \bold \fontsize #3 "Duyek" }
\markup { \vspace #3 }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "1"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ tek8_Δ] r8 tek8_Δ dum4_> tek4_Δ
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "2"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ tek16_Δ ka16_Α] tek8_Δ[ ka8_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] dum16_>[ ka16_Α tek8_Δ] tek4_Δ^>
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "3"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ tek16_Δ ka16_Α] r16 tek16_Δ[ ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] r16 dum16_>[ ka16_Α dum16_> ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] tek4_Δ^>
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "4"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ tek8_Δ] r8 tek8_Δ dum4_> tek8_Δ[ ka16_Α ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "5"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ tek16_Δ ka16_Α] tek8_Δ[ ka8_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] dum16_>[ ka16_Α dum8_>] tek4_Δ^>
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "6"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ tek16_Δ ka16_Α] tek16_Δ[ ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" } tek8_Δ^>] dum16_>[ ka16_Α dum16_> ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] tek4_Δ^>
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "7"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ tek16_Δ ka16_Α] tek16_Δ[ ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" } tek8_Δ^>] dum8_>[ tek16_Δ ka16_Α] tek8_Δ^>[ tek16_Δ ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}
}
\bookpart {
  \tocItem \markup "Εννιάσημος"

\markup { \vspace #0.5 \bold \fontsize #3 "Εννιάσημος" }
\markup { \vspace #3 }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "1"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum4_> tek8_Δ^>[ ka8_Α] dum4_> tek8_Δ^>[ tek8_Δ ka8_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "2"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum4_> tek8_Δ^>[ ka8_Α] dum4_> tek8_Δ^>[ tek16_Δ ka16_Α tek16_Δ ka16_Α]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "3"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ tek16_Δ ka16_Α] tek8_Δ^>[ ka16_Α ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] dum4_> tek8_Δ^>[ tek8_Δ ka8_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "4"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ tek16_Δ ka16_Α] tek8_Δ^>[ tek16_Δ ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] dum4_> tek8_Δ^>[ tek16_Δ ka16_Α tek16_Δ ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "5"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ tek16_Δ ka16_Α] tek8_Δ^>[ tek16_Δ ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] dum8_>[ tek16_Δ ka16_Α] tek8_Δ^>[ tek8_Δ ka8_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "6"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ tek16_Δ ka16_Α] tek8_Δ^>[ tek16_Δ ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }] dum8_>[ tek16_Δ ka16_Α] tek8_Δ^>[ tek16_Δ ka16_Α tek16_Δ ka16_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "7"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum4_> tek4_Δ^> dum4_> tek4._Δ^>
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "8"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum4_> tek4_Δ^> dum4_> tek8_Δ^>[ r8 ka8_Α]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}
}
\bookpart {
  \tocItem \markup "Türk aksağı"

\markup { \vspace #0.5 \bold \fontsize #3 "Türk aksağı" }
\markup { \vspace #3 }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "1"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "2"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "3"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "4"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "5"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum4_> tek8_Δ^>[ tek8_Δ ka8_Α]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "6"
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
      \override TextScript.staff-padding = #2.5
      \override TextScript.outside-staff-priority = ##f
      \override TextScript.self-alignment-X = #CENTER
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
        dum8_>[ tek16_Δ ka16_Α] tek8_Δ^>[ tek8_Δ ka8_\markup { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" }]
      }
      { s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 \noBreak s16 }
    >>
}
}
\bookpart {
  \tocItem \markup "New Rhythms"

\markup { \vspace #0.5 \bold \fontsize #3 "New Rhythms" }

\score {
  \new DrumStaff \with {
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "1"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
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
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "2"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
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
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "3"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
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
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "4"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
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
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "5"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
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
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "6"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
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
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "7"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
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
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "8"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
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
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "9"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
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
      \override StaffSymbol.line-count = #2
      drumStyleTable = #(alist->hash-table darbuka-style-teacher)
      instrumentName = "10"
      \override Staff.TimeSignature.transparent = ##t
      \override VerticalAxisGroup.staff-staff-spacing.basic-distance = #16
      \override VerticalAxisGroup.staff-staff-spacing.padding = #3
      \override StaffSymbol.line-positions = #'(-1 1)
      \override StaffSymbol.stencil = ##f
      \override Clef.stencil = ##f
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
