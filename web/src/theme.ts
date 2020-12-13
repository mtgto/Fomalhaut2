// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import { red } from "@material-ui/core/colors";
import { createMuiTheme, Theme } from "@material-ui/core/styles";

// Create a theme instance.
const theme: Theme = createMuiTheme({
  palette: {
    //type: "dark",
    primary: {
      main: "#556cd6",
    },
    secondary: {
      main: "#19857b",
    },
    error: {
      main: red.A400,
    },
  },
});

export default theme;
