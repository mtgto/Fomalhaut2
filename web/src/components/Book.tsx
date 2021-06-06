// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Box from "@material-ui/core/Box";
import Container from "@material-ui/core/Container";
import SpeedDial from "@material-ui/core/SpeedDial";
import SpeedDialAction from "@material-ui/core/SpeedDialAction";
import SpeedDialIcon from "@material-ui/core/SpeedDialIcon";
import FavoriteIcon from "@material-ui/icons/Favorite";
import FavoriteBorderIcon from "@material-ui/icons/FavoriteBorder";
import KeyboardArrowUpIcon from "@material-ui/icons/KeyboardArrowUp";
import SkipNextIcon from "@material-ui/icons/SkipNext";
import React, { useContext, useEffect, useState } from "react";
import { useNavigate } from "rocon/react";
import { Book } from "../domain/book";
import { message } from "../message";
import { StateContext, toggleLike } from "../reducer";
import theme from "../theme";
import Layout from "./Layout";
import { bookRoutes } from "./Routes";

const pages = (book: Book) => {
  return [...Array(book.pageCount).keys()].map((i: number) => (
    <img
      css={{
        width: "100%",
        maxWidth: "720px",
        minHeight: "200px",
        display: "block",
        margin: "8px auto",
      }}
      key={`${book.id}.${i}`}
      src={`/images/books/${book.id}/pages/${i}`}
    ></img>
  ));
};

type Props = {
  readonly id: string;
};

const BookPage: React.VoidFunctionComponent<Props> = (props: Props) => {
  const [calling, setCalling] = useState(false);
  const [speedDialOpen, setSpeedDialOpen] = useState(false);
  const { state, dispatch } = useContext(StateContext);
  const navigate = useNavigate();
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
  const navigateNextBookId = () => {
    if (nextBookId) {
      navigate(bookRoutes.anyRoute, { id: nextBookId });
    }
  };

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
    navigateNextBookId();
  };

  const handleSpeedDialClose = () => {
    setSpeedDialOpen(false);
  };

  const handleSpeedDialOpen = () => {
    setSpeedDialOpen(true);
  };

  useEffect(() => {
    if (book) {
      document.title = `${book.name} - Fomalhaut2`;
    }
  }, [book]);

  return (
    <Layout title={book?.name}>
      <Container maxWidth="md">
        <Box mx="auto">
          {book ? pages(book) : <span>{message.loading}</span>}
        </Box>
      </Container>
      <SpeedDial
        ariaLabel="direction"
        css={{
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
      </SpeedDial>
    </Layout>
  );
};
export default BookPage;
