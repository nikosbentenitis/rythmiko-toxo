\version "2.24.0"

\header {
  title = "Arabesque"
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
    % Greek / Latin labels under each note are TextScript grobs (the `_X`
    % drummode shorthand). LilyPond defaults to parent-alignment-X = LEFT
    % for scripts, which anchors the text at the note column's left edge.
    % Set BOTH parent and self alignment to CENTER so the text's own
    % center sits on the parent's center, i.e. on the notehead.
    % Center TextScript labels on the actual notehead, not on the
    % NoteColumn's left-edge reference point. The Scheme function below
    % reads the notehead's X-extent and returns its midpoint, then we
    % anchor the script's own center there via self-alignment-X = CENTER.
    \override TextScript.self-alignment-X = #CENTER
    \override TextScript.X-offset =
      #(lambda (grob)
         (let* ((col (ly:grob-parent grob X))
                (heads (and (ly:grob? col)
                            (ly:grob-object col 'note-heads))))
           (if (and (ly:grob-array? heads)
                    (> (ly:grob-array-length heads) 0))
               (let* ((head (ly:grob-array-ref heads 0))
                      (ext  (ly:grob-extent head col X)))
                 (interval-center ext))
               0)))
  }
  \context {
    \Staff
    \override StaffSymbol.staff-space = 7.5
  }
}

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

% Width-scaled variants for tuplet cells: `scale` is the cell's span in
% grid cells (4/3 for one triplet note in a 4-per-beat grid). Same
% height and text placement as the plain cells; only the X extent and
% the divider position move.
#(define-markup-command (tubsCellSBFour layout props scale thick circled text)
  (number? boolean? boolean? string?)
  (let* ((w (* scale 0.9625))
         (hw (/ w 2))
         (thickness (if thick 0.825 0.330)))
    (interpret-markup layout props
      (if circled
        #{ \markup {
             \overlay {
               \with-dimensions #(cons (- hw) hw) #'(-0.4813 . 0.4813)
                 \translate #'(0 . -0.3369)
                 \halign #CENTER \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle \fontsize #-6 #text
               \translate #(cons hw -0.4813)
                 \override #(cons 'thickness thickness)
                 \draw-line #'(0 . 0.9625)
             }
           } #}
        #{ \markup {
             \overlay {
               \with-dimensions #(cons (- hw) hw) #'(-0.4813 . 0.4813)
                 \translate #'(0 . -0.3369)
                 \halign #CENTER \fontsize #-6 #text
               \translate #(cons hw -0.4813)
                 \override #(cons 'thickness thickness)
                 \draw-line #'(0 . 0.9625)
             }
           } #}))))

#(define-markup-command (countCellSBFour layout props scale label)
  (number? string?)
  (let* ((w (* scale 0.9625))
         (hw (/ w 2)))
    (interpret-markup layout props
      #{ \markup {
           \overlay {
             \with-dimensions #(cons (- hw) hw) #'(-0.4000 . 0.4000)
               \translate #'(0 . -0.2800)
               \halign #CENTER \fontsize #-9 #label
             \translate #(cons hw -0.4000)
               \transparent
               \override #'(thickness . 0.330)
               \draw-line #'(0 . 0.8000)
           }
         } #})))

\book {
  \markup { \vspace #2 \fill-line { \fontsize #6 \bold "Arabesque" } }
  \markup { \vspace #1 }
  \markuplist \table-of-contents
  \pageBreak
\bookpart {
  \tocItem \markup "Arabesque"

\markup { \vspace #0.5 \bold \fontsize #3 "Arabesque" }
\markup { \vspace #3 }

\score {
  <<
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
        dum8_\markup { \center-align ">" }[ tek16_\markup { \center-align "Δ" } ka16_\markup { \center-align "Α" }] r16 ka16_\markup { \center-align { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" } }^>[ tek16_\markup { \center-align "Δ" }] r16 dum8_\markup { \center-align ">" }[ tek16_\markup { \center-align "Δ" } ka16_\markup { \center-align "Α" }] tek8_\markup { \center-align "Δ" }^>[ tek16_\markup { \center-align "Δ" } ka16_\markup { \center-align { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" } }]
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
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
        dum8_\markup { \center-align ">" }[ tek16_\markup { \center-align "Δ" } ka16_\markup { \center-align "Α" }] r16 ka16_\markup { \center-align { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" } }^>[ tek16_\markup { \center-align "Δ" }] r16 dum8_\markup { \center-align ">" }[ ka16_\markup { \center-align "Α" } ka16_\markup { \center-align { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" } }] slap8_\markup { \center-align "S" }[ ka16_\markup { \center-align "Α" } ka16_\markup { \center-align { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" } }]
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
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
        dum8_\markup { \center-align ">" }[ tek16_\markup { \center-align "Δ" } ka16_\markup { \center-align "Α" }] r16 ka16_\markup { \center-align { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" } }^>[ tek16_\markup { \center-align "Δ" }] r16 dum16_\markup { \center-align ">" }[ ka16_\markup { \center-align "Α" }] r16 ka16_\markup { \center-align { \override #'(thickness . 1.6) \override #'(circle-padding . 0.35) \circle "Α" } } tek8_\markup { \center-align "Δ" }^>[ tek16_\markup { \center-align "Δ" } ka16_\markup { \center-align "Α" }]
      }
      { s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "|" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "!" \noBreak s16 \bar "." }
    >>
  >>
}

\markup {
  \column {
    \concat {
      \hspace #2 \raise #1 { \bold "1" } \hspace #2
            \center-column {
        { \override #'(box-padding . 0) \override #'(thickness . 0.330) \box \concat { \tubsCellBFour ">" \tubsCellBFour " " \tubsCellBFour "δ" \tubsCellThickBFour "α" \tubsCellBFour " " \tubsCellCircleBFour "Α" \tubsCellBFour "δ" \tubsCellThickBFour " " \tubsCellBFour ">" \tubsCellBFour " " \tubsCellBFour "δ" \tubsCellThickBFour "α" \tubsCellBFour "Δ" \tubsCellBFour " " \tubsCellBFour "δ" \tubsCellCircleThickBFour "α" } }
        { \override #'(box-padding . 0) \override #'(thickness . 0.330) \box \concat { \tubsCellBFour "D" \tubsCellBFour " " \tubsCellBFour "t" \tubsCellThickBFour "k" \tubsCellBFour " " \tubsCellCircleBFour "K" \tubsCellBFour "t" \tubsCellThickBFour " " \tubsCellBFour "D" \tubsCellBFour " " \tubsCellBFour "t" \tubsCellThickBFour "k" \tubsCellBFour "T" \tubsCellBFour " " \tubsCellBFour "t" \tubsCellCircleThickBFour "k" } }
        \concat { \countCellBFour "1" \countCellBFour "e" \countCellBFour "+" \countCellBFour "a" \countCellBFour "2" \countCellBFour "e" \countCellBFour "+" \countCellBFour "a" \countCellBFour "3" \countCellBFour "e" \countCellBFour "+" \countCellBFour "a" \countCellBFour "4" \countCellBFour "e" \countCellBFour "+" \countCellBFour "a" }
      }
    }
    \vspace #0.5
    \concat {
      \hspace #2 \raise #1 { \bold "2" } \hspace #2
            \center-column {
        { \override #'(box-padding . 0) \override #'(thickness . 0.330) \box \concat { \tubsCellBFour ">" \tubsCellBFour " " \tubsCellBFour "δ" \tubsCellThickBFour "α" \tubsCellBFour " " \tubsCellCircleBFour "Α" \tubsCellBFour "δ" \tubsCellThickBFour " " \tubsCellBFour ">" \tubsCellBFour " " \tubsCellBFour "α" \tubsCellCircleThickBFour "α" \tubsCellBFour "S" \tubsCellBFour " " \tubsCellBFour "α" \tubsCellCircleThickBFour "α" } }
        { \override #'(box-padding . 0) \override #'(thickness . 0.330) \box \concat { \tubsCellBFour "D" \tubsCellBFour " " \tubsCellBFour "t" \tubsCellThickBFour "k" \tubsCellBFour " " \tubsCellCircleBFour "K" \tubsCellBFour "t" \tubsCellThickBFour " " \tubsCellBFour "D" \tubsCellBFour " " \tubsCellBFour "k" \tubsCellCircleThickBFour "k" \tubsCellBFour "S" \tubsCellBFour " " \tubsCellBFour "k" \tubsCellCircleThickBFour "k" } }
        \concat { \countCellBFour "1" \countCellBFour "e" \countCellBFour "+" \countCellBFour "a" \countCellBFour "2" \countCellBFour "e" \countCellBFour "+" \countCellBFour "a" \countCellBFour "3" \countCellBFour "e" \countCellBFour "+" \countCellBFour "a" \countCellBFour "4" \countCellBFour "e" \countCellBFour "+" \countCellBFour "a" }
      }
    }
    \vspace #0.5
    \concat {
      \hspace #2 \raise #1 { \bold "3" } \hspace #2
            \center-column {
        { \override #'(box-padding . 0) \override #'(thickness . 0.330) \box \concat { \tubsCellBFour ">" \tubsCellBFour " " \tubsCellBFour "δ" \tubsCellThickBFour "α" \tubsCellBFour " " \tubsCellCircleBFour "Α" \tubsCellBFour "δ" \tubsCellThickBFour " " \tubsCellBFour ">" \tubsCellBFour "α" \tubsCellBFour " " \tubsCellCircleThickBFour "α" \tubsCellBFour "Δ" \tubsCellBFour " " \tubsCellBFour "δ" \tubsCellThickBFour "α" } }
        { \override #'(box-padding . 0) \override #'(thickness . 0.330) \box \concat { \tubsCellBFour "D" \tubsCellBFour " " \tubsCellBFour "t" \tubsCellThickBFour "k" \tubsCellBFour " " \tubsCellCircleBFour "K" \tubsCellBFour "t" \tubsCellThickBFour " " \tubsCellBFour "D" \tubsCellBFour "k" \tubsCellBFour " " \tubsCellCircleThickBFour "k" \tubsCellBFour "T" \tubsCellBFour " " \tubsCellBFour "t" \tubsCellThickBFour "k" } }
        \concat { \countCellBFour "1" \countCellBFour "e" \countCellBFour "+" \countCellBFour "a" \countCellBFour "2" \countCellBFour "e" \countCellBFour "+" \countCellBFour "a" \countCellBFour "3" \countCellBFour "e" \countCellBFour "+" \countCellBFour "a" \countCellBFour "4" \countCellBFour "e" \countCellBFour "+" \countCellBFour "a" }
      }
    }
  }
}
}
}
