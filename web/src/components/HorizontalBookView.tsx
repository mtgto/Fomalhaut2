// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Box from "@mui/material/Box";
import type { History } from "history";
import { MutableRefObject, useEffect, useRef, useState } from "react";
import { useInView } from "react-intersection-observer";
import { useHistory } from "rocon/react";
import { Book } from "../domain/book";
import NavigationPage from "./NavigationPage";

type Props = Readonly<{
  book: Book;
  nextBook?: Book;
  direction: "left" | "right";
  onNext: () => void;
  onRandom: () => void;
}>;

const pages = (
  book: Book,
  history: History,
  refs: MutableRefObject<HTMLElement[]>
) => {
  return [...Array(book.pageCount).keys()].map((i: number) => {
    const { ref } = useInView({
      onChange: (inView) => {
        if (inView) {
          history.replace({ hash: `${i}` });
        }
      },
    });
    return (
      <Box
        id={`${i}`}
        ref={(element: HTMLElement) => (refs.current[i] = element)}
        key={i}
        display="flex"
        mx="auto"
        width="100%"
        height="100%"
        flexShrink={0}
        sx={{ scrollSnapAlign: "start" }}
      >
        <Box
          ref={ref}
          component="img"
          loading="lazy" // TODO: Load first 3 pages
          my="auto"
          mx="auto"
          maxHeight="100%"
          maxWidth="100%"
          src={`/images/books/${book.id}/pages/${i}`}
          display="block"
        />
      </Box>
    );
  });
};

const HorizontalBookView = (props: Props) => {
  const refs = useRef<HTMLElement[]>([]);
  const history = useHistory();
  const [initialHash] = useState(location.hash);

  useEffect(() => {
    const pageIndex = parseInt(initialHash.substring(1));
    if (!isNaN(pageIndex)) {
      if (refs.current && refs.current[pageIndex]) {
        refs.current[pageIndex].scrollIntoView();
      }
    }
    //topRef.current?.scrollIntoView();
  }, [props.book, initialHash]);

  return (
    <Box
      display="flex"
      flexDirection={props.direction === "right" ? "row" : "row-reverse"}
      sx={{
        width: "100%",
        height: "100vh",
        scrollSnapType: "x mandatory",
        overflowX: "auto",
      }}
    >
      {pages(props.book, history, refs)}
      <Box
        display="flex"
        flexDirection="column"
        width="100%"
        height="100%"
        flexShrink={0}
        justifyContent="center"
        alignItems="center"
        sx={{ scrollSnapAlign: "start" }}
      >
        <NavigationPage
          book={props.book}
          nextBook={props.nextBook}
          onNext={props.onNext}
          onRandom={props.onRandom}
        />
      </Box>
    </Box>
  );
};

export default HorizontalBookView;
