// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import FavoriteIcon from "@mui/icons-material/Favorite";
import Card from "@mui/material/Card";
import CardContent from "@mui/material/CardContent";
import CardMedia from "@mui/material/CardMedia";
import { pink } from "@mui/material/colors";
import Link from "@mui/material/Link";
import Typography from "@mui/material/Typography";
import React, { forwardRef, useMemo } from "react";
import { Link as RouterLink } from "rocon/react";
import { Book } from "../domain/book";
import { bookRoutes } from "./Routes";

type Props = {
  book: Book;
};

const Cover: React.VoidFunctionComponent<Props> = (props: Props) => {
  const BookLink = useMemo(
    () =>
      // eslint-disable-next-line react/display-name
      forwardRef((linkProps, _ref) => (
        <RouterLink
          route={bookRoutes.anyRoute}
          match={{ id: props.book.id }}
          {...linkProps}
        ></RouterLink>
      )),
    [props.book.id]
  );
  return (
    <Link component={BookLink}>
      <Card
        variant="outlined"
        css={{ height: "100%", position: "relative" }}
        square
      >
        <CardMedia
          component="img"
          css={{ objectFit: "cover" }}
          image={`/images/books/${props.book.id}/thumbnail`}
        />
        {props.book.like && (
          <FavoriteIcon
            css={{
              position: "absolute",
              top: "0px",
              right: "0px",
              color: pink[200],
            }}
          />
        )}
        <CardContent
          css={{
            padding: "4px",
            "&:last-child": {
              paddingBottom: "inherit",
            },
          }}
        >
          <Typography
            gutterBottom
            variant="subtitle2"
            css={{
              display: "-webkit-box",
              WebkitLineClamp: 2,
              WebkitBoxOrient: "vertical",
              overflow: "hidden",
            }}
            component="p"
            title={props.book.name}
          >
            {props.book.name}
          </Typography>
        </CardContent>
      </Card>
    </Link>
  );
};
export default Cover;
