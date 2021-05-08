// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { Path, Search, useRoutes } from "rocon/react";
import BookPage from "./Book";
import CollectionPage from "./Collection";
import FilterPage from "./Filter";

export const bookRoutes = Path().any("id", {
  action: ({ id }) => {
    const bookPage = <BookPage id={id} />;
    return bookPage;
  },
});
export const collectionRoutes = Path()
  .any("id")
  .anyRoute.attach(Search("page", { optional: true }))
  .action(({ id, page }) => {
    const collectionPage = (
      <CollectionPage id={id} page={page ? Number(page) : undefined} />
    );
    return collectionPage;
  });
export const filterRoutes = Path()
  .any("id")
  .anyRoute.attach(Search("page", { optional: true }))
  .action(({ id, page }) => {
    const filterPage = (
      <FilterPage id={id} page={page ? Number(page) : undefined} />
    );
    return filterPage;
  });
export const topLevelRoutes = Path()
  .exact({
    action: () => {
      const filterPage = <FilterPage id={"all"} />;
      return filterPage;
    },
  })
  .route("books", (route) => route.attach(bookRoutes))
  .route("collections", (route) => route.attach(collectionRoutes))
  .route("filters", (route) => route.attach(filterRoutes));

const Routes: React.VoidFunctionComponent = () => {
  return useRoutes(topLevelRoutes);
};

export default Routes;
