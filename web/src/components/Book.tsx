// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { useContext, useEffect, useState } from "react";
import { useNavigate } from "rocon/react";
import FavoriteIcon from "@mui/icons-material/Favorite";
import FavoriteBorderIcon from "@mui/icons-material/FavoriteBorder";
import KeyboardArrowUpIcon from "@mui/icons-material/KeyboardArrowUp";
import SkipNextIcon from "@mui/icons-material/SkipNext";
import SkipPreviousIcon from "@mui/icons-material/SkipPrevious";
import Container from "@mui/material/Container";
import SpeedDial from "@mui/material/SpeedDial";
import SpeedDialAction from "@mui/material/SpeedDialAction";
import SpeedDialIcon from "@mui/material/SpeedDialIcon";
import { useTheme } from "@mui/material/styles";
import { Book } from "../domain/book";
import { message } from "../message";
import { StateContext, toggleLike } from "../reducer";
import HorizontalBookView from "./HorizontalBookView";
import Layout from "./Layout";
import { bookRoutes } from "./Routes";
import VerticalBookView from "./VerticalBookView";

type Props = {
  readonly id: string;
};

const BookPage: React.FunctionComponent<Props> = (props: Props) => {
  const [calling, setCalling] = useState(false);
  const [speedDialOpen, setSpeedDialOpen] = useState(false);
  const { state, dispatch } = useContext(StateContext);
  const navigate = useNavigate();
  const theme = useTheme();
  const book: Book | undefined = state.books.find(
    (book) => book.id === props.id
  );
  const currentBookIndex = state.selectedBookIds.findIndex(
    (bookId) => props.id === bookId
  );
  const nextBookId: string | undefined =
    state.selectedBookIds.length > currentBookIndex + 1
      ? state.selectedBookIds[currentBookIndex + 1]
      : undefined;
  const nextBook: Book | undefined = nextBookId
    ? state.books.find((book) => book.id === nextBookId)
    : undefined;

  const navigateBookId = (bookId: string | undefined) => {
    if (bookId) {
      navigate(bookRoutes.anyRoute, { id: bookId });
    }
  };
  const prevBookId: string | undefined =
    currentBookIndex > 0
      ? state.selectedBookIds[currentBookIndex - 1]
      : undefined;

  const handleScrollToTop = () => {
    window.scrollTo({ top: 0, behavior: "smooth" });
    setSpeedDialOpen(false);
  };

  const handleToggleLike = async () => {
    if (book) {
      setCalling(true);
      try {
        await fetch(
          `/api/v1/books/${book.id}/${book.like ? "dislike" : "like"}`,
          { method: "POST" }
        );
        dispatch(toggleLike(book.id));
      } catch (error) {
        console.error(error);
      } finally {
        setCalling(false);
      }
    }
  };

  const handleNext = () => {
    navigateBookId(nextBookId);
    window.scrollTo(0, 0);
  };

  const handlePrev = () => {
    navigateBookId(prevBookId);
    window.scrollTo(0, 0);
  };

  const handleSpeedDialClose = () => {
    setSpeedDialOpen(false);
  };

  const handleSpeedDialOpen = () => {
    setSpeedDialOpen(true);
  };

  const handleRandom = () => {
    if (state.books.length > 0) {
      const index = Math.floor(Math.random() * state.books.length);
      const book = state.books[index];
      navigate(bookRoutes.anyRoute, { id: book.id });
    }
  };

  useEffect(() => {
    if (book) {
      document.title = `${book.name} - Fomalhaut2`;
    }
  }, [book]);

  return (
    <Layout title={book?.name}>
      <Container maxWidth="md">
        {book ? (
          state.viewMode === "left" || state.viewMode === "right" ? (
            <HorizontalBookView
              book={book}
              nextBook={nextBook}
              direction={state.viewMode}
              onNext={handleNext}
              onRandom={handleRandom}
            />
          ) : (
            <VerticalBookView
              book={book}
              nextBook={nextBook}
              onNext={handleNext}
              onRandom={handleRandom}
            />
          )
        ) : (
          <span>{message.loading}</span>
        )}
      </Container>
      <SpeedDial
        ariaLabel="direction"
        sx={{
          position: "fixed",
          bottom: theme.spacing(8),
          right: theme.spacing(2),
        }}
        open={speedDialOpen}
        onOpen={handleSpeedDialOpen}
        onClose={handleSpeedDialClose}
        icon={<SpeedDialIcon />}
      >
        <SpeedDialAction
          onClick={handleScrollToTop}
          icon={<KeyboardArrowUpIcon />}
          tooltipTitle={message.commands.scrollToTop}
        />
        <SpeedDialAction
          onClick={handleToggleLike}
          FabProps={{ disabled: calling }}
          icon={book?.like ? <FavoriteIcon /> : <FavoriteBorderIcon />}
          tooltipTitle={
            book?.like ? message.commands.dislike : message.commands.like
          }
        />
        {nextBookId ? (
          <SpeedDialAction
            onClick={handleNext}
            icon={<SkipNextIcon />}
            tooltipTitle={message.commands.next}
          />
        ) : null}
        {prevBookId ? (
          <SpeedDialAction
            onClick={handlePrev}
            icon={<SkipPreviousIcon />}
            tooltipTitle={message.commands.prev}
          />
        ) : null}
      </SpeedDial>
    </Layout>
  );
};
export default BookPage;
