"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/collection.tsx
var collection_exports = {};
__export(collection_exports, {
  default: () => PhotoCollection
});
module.exports = __toCommonJS(collection_exports);
var import_react = require("react");
var import_api4 = require("@raycast/api");

// src/loadPhotos.ts
var import_fs2 = require("fs");
var import_path2 = __toESM(require("path"));
var import_api2 = require("@raycast/api");

// src/photoMetadata.ts
var import_fs = require("fs");
var import_path = __toESM(require("path"));
var import_api = require("@raycast/api");
async function readPhotoMetadata() {
  const dir = import_path.default.join(PHOTO_DIR, "metadata.json");
  try {
    const data = await import_fs.promises.readFile(dir);
    return JSON.parse(data.toString());
  } catch (error) {
    if (error.code === "ENOENT") {
      await import_fs.promises.writeFile(dir, JSON.stringify({}), "utf-8");
      return {};
    }
    console.error("Error reading metadata:", error);
    return {};
  }
}

// src/loadPhotos.ts
var PHOTO_DIR = import_path2.default.join(import_api2.environment.supportPath, "PhotoCollection");
async function ensureDirectoryExists() {
  try {
    const stats = await import_fs2.promises.stat(PHOTO_DIR);
    if (!stats.isDirectory()) {
      throw new Error("Not a directory");
    }
  } catch (error) {
    await import_fs2.promises.mkdir(PHOTO_DIR, { recursive: true });
  }
}
async function loadPhotosFromDisk() {
  try {
    const files = await import_fs2.promises.readdir(PHOTO_DIR);
    const photoFiles = files.filter((file) => /\.(jpg|jpeg|png|gif|webp)$/i.test(file));
    console.log(files);
    const photoData = await Promise.all(
      photoFiles.map(async (file) => {
        const filePath = import_path2.default.join(PHOTO_DIR, file);
        const stats = await import_fs2.promises.stat(filePath);
        return {
          path: filePath,
          name: file,
          dateAdded: stats.birthtime
        };
      })
    );
    return photoData.sort((a, b) => b.dateAdded.getTime() - a.dateAdded.getTime());
  } catch (error) {
    console.log("Error in load balle: ", error);
    (0, import_api2.showToast)({
      style: import_api2.Toast.Style.Failure,
      title: "Failed to load photos",
      message: String(error)
    });
    return [];
  }
}
async function initializeAndLoadPhotos() {
  await ensureDirectoryExists();
  const metadata = await readPhotoMetadata();
  const photos = await loadPhotosFromDisk();
  const meta = photos.map((photo) => {
    const photoMetadata = metadata[photo.name] || {};
    return {
      ...photo,
      ...photoMetadata
    };
  });
  return meta;
}
function openCollectionFolder() {
  (0, import_api2.showInFinder)(PHOTO_DIR);
}

// src/deletePhoto.ts
var import_fs3 = require("fs");
var import_api3 = require("@raycast/api");
async function deletePhoto(photoPath) {
  try {
    await import_fs3.promises.unlink(photoPath);
    return true;
  } catch (error) {
    await (0, import_api3.showToast)({
      style: import_api3.Toast.Style.Failure,
      title: "Failed to remove photo",
      message: String(error)
    });
    return false;
  }
}
async function confirmAndDeletePhoto(photoPath) {
  const confirmed = await (0, import_api3.confirmAlert)({
    title: "Delete Photo",
    message: "Are you sure you want to delete this photo from your collection?",
    primaryAction: {
      title: "Delete",
      style: import_api3.Alert.ActionStyle.Destructive
    }
  });
  if (confirmed) {
    const success = await deletePhoto(photoPath);
    if (success) {
      await (0, import_api3.showToast)({
        style: import_api3.Toast.Style.Success,
        title: "Photo removed from collection"
      });
    }
    return success;
  }
  return false;
}

// src/collection.tsx
var import_jsx_runtime = require("react/jsx-runtime");
function PhotoCollection() {
  const [photos, setPhotos] = (0, import_react.useState)([]);
  const [isLoading, setIsLoading] = (0, import_react.useState)(true);
  const [columns, setColumns] = (0, import_react.useState)(5);
  (0, import_react.useEffect)(() => {
    loadPhotos();
  }, []);
  async function loadPhotos() {
    setIsLoading(true);
    try {
      const photoData = await initializeAndLoadPhotos();
      setPhotos(photoData);
    } finally {
      setIsLoading(false);
    }
  }
  async function handleDeletePhoto(photoPath) {
    const success = await confirmAndDeletePhoto(photoPath);
    if (success) {
      setPhotos(photos.filter((photo) => photo.path !== photoPath));
    }
  }
  return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
    import_api4.Grid,
    {
      columns,
      inset: import_api4.Grid.Inset.Large,
      isLoading,
      searchBarPlaceholder: "Search photos...",
      searchBarAccessory: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(
        import_api4.Grid.Dropdown,
        {
          tooltip: "Grid Item Size",
          storeValue: true,
          onChange: (newValue) => {
            setColumns(parseInt(newValue));
          },
          children: [
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api4.Grid.Dropdown.Item, { title: "Large", value: "3" }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api4.Grid.Dropdown.Item, { title: "Medium", value: "5" }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api4.Grid.Dropdown.Item, { title: "Small", value: "8" })
          ]
        }
      ),
      children: photos.length === 0 && !isLoading ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
        import_api4.Grid.EmptyView,
        {
          title: "No Photos in Collection",
          description: "Add photos to your collection to see them here.",
          actions: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_api4.ActionPanel, { children: [
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api4.Action, { title: "Open Collection Folder", onAction: openCollectionFolder }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api4.Action, { title: "Refresh", onAction: loadPhotos, shortcut: { modifiers: ["cmd"], key: "r" } })
          ] })
        }
      ) : photos.map((photo) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
        import_api4.Grid.Item,
        {
          content: photo.path,
          title: photo.name,
          subtitle: new Date(photo.dateAdded).toLocaleDateString(),
          actions: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_api4.ActionPanel, { children: [
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api4.Action.OpenWith, { path: photo.path, title: "Open With" }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api4.Action, { title: "Show in Finder", onAction: () => (0, import_api4.showInFinder)(photo.path) }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api4.Action.CopyToClipboard, { title: "Copy Path", content: photo.path }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
              import_api4.Action.CopyToClipboard,
              {
                title: "Copy Image",
                content: { file: photo.path },
                shortcut: { modifiers: ["cmd"], key: "c" }
              }
            ),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api4.Action, { title: "Open Collection Folder", onAction: openCollectionFolder }),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
              import_api4.Action,
              {
                title: "Remove from Collection",
                style: import_api4.Action.Style.Destructive,
                onAction: () => handleDeletePhoto(photo.path),
                shortcut: { modifiers: ["cmd"], key: "backspace" }
              }
            )
          ] })
        },
        photo.path
      ))
    }
  );
}
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vLi4vLi4vRG9jdW1lbnRzL3JheWNhc3QvY29sbGVjdGlvbi9zcmMvY29sbGVjdGlvbi50c3giLCAiLi4vLi4vLi4vLi4vRG9jdW1lbnRzL3JheWNhc3QvY29sbGVjdGlvbi9zcmMvbG9hZFBob3Rvcy50cyIsICIuLi8uLi8uLi8uLi9Eb2N1bWVudHMvcmF5Y2FzdC9jb2xsZWN0aW9uL3NyYy9waG90b01ldGFkYXRhLnRzIiwgIi4uLy4uLy4uLy4uL0RvY3VtZW50cy9yYXljYXN0L2NvbGxlY3Rpb24vc3JjL2RlbGV0ZVBob3RvLnRzIl0sCiAgInNvdXJjZXNDb250ZW50IjogWyJpbXBvcnQgeyB1c2VTdGF0ZSwgdXNlRWZmZWN0IH0gZnJvbSBcInJlYWN0XCI7XG5pbXBvcnQgeyBBY3Rpb25QYW5lbCwgQWN0aW9uLCBHcmlkLCBzaG93SW5GaW5kZXIgfSBmcm9tIFwiQHJheWNhc3QvYXBpXCI7XG5pbXBvcnQgeyBQaG90byB9IGZyb20gXCIuL3R5cGVzXCI7XG5pbXBvcnQgeyBpbml0aWFsaXplQW5kTG9hZFBob3Rvcywgb3BlbkNvbGxlY3Rpb25Gb2xkZXIgfSBmcm9tIFwiLi9sb2FkUGhvdG9zXCI7XG5pbXBvcnQgeyBjb25maXJtQW5kRGVsZXRlUGhvdG8gfSBmcm9tIFwiLi9kZWxldGVQaG90b1wiO1xuXG5leHBvcnQgZGVmYXVsdCBmdW5jdGlvbiBQaG90b0NvbGxlY3Rpb24oKSB7XG4gIGNvbnN0IFtwaG90b3MsIHNldFBob3Rvc10gPSB1c2VTdGF0ZTxQaG90b1tdPihbXSk7XG4gIGNvbnN0IFtpc0xvYWRpbmcsIHNldElzTG9hZGluZ10gPSB1c2VTdGF0ZSh0cnVlKTtcbiAgY29uc3QgW2NvbHVtbnMsIHNldENvbHVtbnNdID0gdXNlU3RhdGUoNSk7XG5cbiAgdXNlRWZmZWN0KCgpID0+IHtcbiAgICBsb2FkUGhvdG9zKCk7XG4gIH0sIFtdKTtcblxuICBhc3luYyBmdW5jdGlvbiBsb2FkUGhvdG9zKCkge1xuICAgIHNldElzTG9hZGluZyh0cnVlKTtcbiAgICB0cnkge1xuICAgICAgY29uc3QgcGhvdG9EYXRhID0gYXdhaXQgaW5pdGlhbGl6ZUFuZExvYWRQaG90b3MoKTtcbiAgICAgIHNldFBob3RvcyhwaG90b0RhdGEpO1xuICAgIH0gZmluYWxseSB7XG4gICAgICBzZXRJc0xvYWRpbmcoZmFsc2UpO1xuICAgIH1cbiAgfVxuXG4gIGFzeW5jIGZ1bmN0aW9uIGhhbmRsZURlbGV0ZVBob3RvKHBob3RvUGF0aDogc3RyaW5nKSB7XG4gICAgY29uc3Qgc3VjY2VzcyA9IGF3YWl0IGNvbmZpcm1BbmREZWxldGVQaG90byhwaG90b1BhdGgpO1xuICAgIGlmIChzdWNjZXNzKSB7XG4gICAgICBzZXRQaG90b3MocGhvdG9zLmZpbHRlcigocGhvdG8pID0+IHBob3RvLnBhdGggIT09IHBob3RvUGF0aCkpO1xuICAgIH1cbiAgfVxuXG4gIHJldHVybiAoXG4gICAgPEdyaWRcbiAgICAgIGNvbHVtbnM9e2NvbHVtbnN9XG4gICAgICBpbnNldD17R3JpZC5JbnNldC5MYXJnZX1cbiAgICAgIGlzTG9hZGluZz17aXNMb2FkaW5nfVxuICAgICAgc2VhcmNoQmFyUGxhY2Vob2xkZXI9XCJTZWFyY2ggcGhvdG9zLi4uXCJcbiAgICAgIHNlYXJjaEJhckFjY2Vzc29yeT17XG4gICAgICAgIDxHcmlkLkRyb3Bkb3duXG4gICAgICAgICAgdG9vbHRpcD1cIkdyaWQgSXRlbSBTaXplXCJcbiAgICAgICAgICBzdG9yZVZhbHVlXG4gICAgICAgICAgb25DaGFuZ2U9eyhuZXdWYWx1ZSkgPT4ge1xuICAgICAgICAgICAgc2V0Q29sdW1ucyhwYXJzZUludChuZXdWYWx1ZSkpO1xuICAgICAgICAgIH19XG4gICAgICAgID5cbiAgICAgICAgICA8R3JpZC5Ecm9wZG93bi5JdGVtIHRpdGxlPVwiTGFyZ2VcIiB2YWx1ZT17XCIzXCJ9IC8+XG4gICAgICAgICAgPEdyaWQuRHJvcGRvd24uSXRlbSB0aXRsZT1cIk1lZGl1bVwiIHZhbHVlPXtcIjVcIn0gLz5cbiAgICAgICAgICA8R3JpZC5Ecm9wZG93bi5JdGVtIHRpdGxlPVwiU21hbGxcIiB2YWx1ZT17XCI4XCJ9IC8+XG4gICAgICAgIDwvR3JpZC5Ecm9wZG93bj5cbiAgICAgIH1cbiAgICA+XG4gICAgICB7cGhvdG9zLmxlbmd0aCA9PT0gMCAmJiAhaXNMb2FkaW5nID8gKFxuICAgICAgICA8R3JpZC5FbXB0eVZpZXdcbiAgICAgICAgICB0aXRsZT1cIk5vIFBob3RvcyBpbiBDb2xsZWN0aW9uXCJcbiAgICAgICAgICBkZXNjcmlwdGlvbj1cIkFkZCBwaG90b3MgdG8geW91ciBjb2xsZWN0aW9uIHRvIHNlZSB0aGVtIGhlcmUuXCJcbiAgICAgICAgICBhY3Rpb25zPXtcbiAgICAgICAgICAgIDxBY3Rpb25QYW5lbD5cbiAgICAgICAgICAgICAgPEFjdGlvbiB0aXRsZT1cIk9wZW4gQ29sbGVjdGlvbiBGb2xkZXJcIiBvbkFjdGlvbj17b3BlbkNvbGxlY3Rpb25Gb2xkZXJ9IC8+XG4gICAgICAgICAgICAgIDxBY3Rpb24gdGl0bGU9XCJSZWZyZXNoXCIgb25BY3Rpb249e2xvYWRQaG90b3N9IHNob3J0Y3V0PXt7IG1vZGlmaWVyczogW1wiY21kXCJdLCBrZXk6IFwiclwiIH19IC8+XG4gICAgICAgICAgICA8L0FjdGlvblBhbmVsPlxuICAgICAgICAgIH1cbiAgICAgICAgLz5cbiAgICAgICkgOiAoXG4gICAgICAgIHBob3Rvcy5tYXAoKHBob3RvKSA9PiAoXG4gICAgICAgICAgPEdyaWQuSXRlbVxuICAgICAgICAgICAga2V5PXtwaG90by5wYXRofVxuICAgICAgICAgICAgY29udGVudD17cGhvdG8ucGF0aH1cbiAgICAgICAgICAgIHRpdGxlPXtwaG90by5uYW1lfVxuICAgICAgICAgICAgc3VidGl0bGU9e25ldyBEYXRlKHBob3RvLmRhdGVBZGRlZCkudG9Mb2NhbGVEYXRlU3RyaW5nKCl9XG4gICAgICAgICAgICBhY3Rpb25zPXtcbiAgICAgICAgICAgICAgPEFjdGlvblBhbmVsPlxuICAgICAgICAgICAgICAgIDxBY3Rpb24uT3BlbldpdGggcGF0aD17cGhvdG8ucGF0aH0gdGl0bGU9XCJPcGVuIFdpdGhcIiAvPlxuICAgICAgICAgICAgICAgIDxBY3Rpb24gdGl0bGU9XCJTaG93IGluIEZpbmRlclwiIG9uQWN0aW9uPXsoKSA9PiBzaG93SW5GaW5kZXIocGhvdG8ucGF0aCl9IC8+XG4gICAgICAgICAgICAgICAgPEFjdGlvbi5Db3B5VG9DbGlwYm9hcmQgdGl0bGU9XCJDb3B5IFBhdGhcIiBjb250ZW50PXtwaG90by5wYXRofSAvPlxuICAgICAgICAgICAgICAgIDxBY3Rpb24uQ29weVRvQ2xpcGJvYXJkXG4gICAgICAgICAgICAgICAgICB0aXRsZT1cIkNvcHkgSW1hZ2VcIlxuICAgICAgICAgICAgICAgICAgY29udGVudD17eyBmaWxlOiBwaG90by5wYXRoIH19XG4gICAgICAgICAgICAgICAgICBzaG9ydGN1dD17eyBtb2RpZmllcnM6IFtcImNtZFwiXSwga2V5OiBcImNcIiB9fVxuICAgICAgICAgICAgICAgIC8+XG4gICAgICAgICAgICAgICAgPEFjdGlvbiB0aXRsZT1cIk9wZW4gQ29sbGVjdGlvbiBGb2xkZXJcIiBvbkFjdGlvbj17b3BlbkNvbGxlY3Rpb25Gb2xkZXJ9IC8+XG4gICAgICAgICAgICAgICAgPEFjdGlvblxuICAgICAgICAgICAgICAgICAgdGl0bGU9XCJSZW1vdmUgZnJvbSBDb2xsZWN0aW9uXCJcbiAgICAgICAgICAgICAgICAgIHN0eWxlPXtBY3Rpb24uU3R5bGUuRGVzdHJ1Y3RpdmV9XG4gICAgICAgICAgICAgICAgICBvbkFjdGlvbj17KCkgPT4gaGFuZGxlRGVsZXRlUGhvdG8ocGhvdG8ucGF0aCl9XG4gICAgICAgICAgICAgICAgICBzaG9ydGN1dD17eyBtb2RpZmllcnM6IFtcImNtZFwiXSwga2V5OiBcImJhY2tzcGFjZVwiIH19XG4gICAgICAgICAgICAgICAgLz5cbiAgICAgICAgICAgICAgPC9BY3Rpb25QYW5lbD5cbiAgICAgICAgICAgIH1cbiAgICAgICAgICAvPlxuICAgICAgICApKVxuICAgICAgKX1cbiAgICA8L0dyaWQ+XG4gICk7XG59XG4iLCAiaW1wb3J0IHsgcHJvbWlzZXMgYXMgZnMgfSBmcm9tIFwiZnNcIjtcbmltcG9ydCBwYXRoIGZyb20gXCJwYXRoXCI7XG5pbXBvcnQgeyBlbnZpcm9ubWVudCwgc2hvd1RvYXN0LCBUb2FzdCwgc2hvd0luRmluZGVyIH0gZnJvbSBcIkByYXljYXN0L2FwaVwiO1xuaW1wb3J0IHsgUGhvdG8gfSBmcm9tIFwiLi90eXBlc1wiO1xuaW1wb3J0IHsgcmVhZFBob3RvTWV0YWRhdGEgfSBmcm9tIFwiLi9waG90b01ldGFkYXRhXCI7XG5cbmV4cG9ydCBjb25zdCBQSE9UT19ESVIgPSBwYXRoLmpvaW4oZW52aXJvbm1lbnQuc3VwcG9ydFBhdGgsIFwiUGhvdG9Db2xsZWN0aW9uXCIpO1xuXG4vKipcbiAqIEVuc3VyZXMgdGhlIHBob3RvIGNvbGxlY3Rpb24gZGlyZWN0b3J5IGV4aXN0c1xuICovXG5leHBvcnQgYXN5bmMgZnVuY3Rpb24gZW5zdXJlRGlyZWN0b3J5RXhpc3RzKCk6IFByb21pc2U8dm9pZD4ge1xuICB0cnkge1xuICAgIGNvbnN0IHN0YXRzID0gYXdhaXQgZnMuc3RhdChQSE9UT19ESVIpO1xuICAgIGlmICghc3RhdHMuaXNEaXJlY3RvcnkoKSkge1xuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiTm90IGEgZGlyZWN0b3J5XCIpO1xuICAgIH1cbiAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICAvLyBEaXJlY3RvcnkgZG9lc24ndCBleGlzdCwgY3JlYXRlIGl0XG4gICAgYXdhaXQgZnMubWtkaXIoUEhPVE9fRElSLCB7IHJlY3Vyc2l2ZTogdHJ1ZSB9KTtcbiAgfVxufVxuXG4vKipcbiAqIExvYWRzIHBob3RvcyBmcm9tIHRoZSBjb2xsZWN0aW9uIGRpcmVjdG9yeVxuICovXG5leHBvcnQgYXN5bmMgZnVuY3Rpb24gbG9hZFBob3Rvc0Zyb21EaXNrKCk6IFByb21pc2U8UGhvdG9bXT4ge1xuICB0cnkge1xuICAgIGNvbnN0IGZpbGVzID0gYXdhaXQgZnMucmVhZGRpcihQSE9UT19ESVIpO1xuICAgIGNvbnN0IHBob3RvRmlsZXMgPSBmaWxlcy5maWx0ZXIoKGZpbGUpID0+IC9cXC4oanBnfGpwZWd8cG5nfGdpZnx3ZWJwKSQvaS50ZXN0KGZpbGUpKTtcblxuICAgIGNvbnNvbGUubG9nKGZpbGVzKTtcblxuICAgIGNvbnN0IHBob3RvRGF0YSA9IGF3YWl0IFByb21pc2UuYWxsKFxuICAgICAgcGhvdG9GaWxlcy5tYXAoYXN5bmMgKGZpbGUpID0+IHtcbiAgICAgICAgY29uc3QgZmlsZVBhdGggPSBwYXRoLmpvaW4oUEhPVE9fRElSLCBmaWxlKTtcbiAgICAgICAgY29uc3Qgc3RhdHMgPSBhd2FpdCBmcy5zdGF0KGZpbGVQYXRoKTtcbiAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICBwYXRoOiBmaWxlUGF0aCxcbiAgICAgICAgICBuYW1lOiBmaWxlLFxuICAgICAgICAgIGRhdGVBZGRlZDogc3RhdHMuYmlydGh0aW1lLFxuICAgICAgICB9O1xuICAgICAgfSksXG4gICAgKTtcblxuICAgIHJldHVybiBwaG90b0RhdGEuc29ydCgoYSwgYikgPT4gYi5kYXRlQWRkZWQuZ2V0VGltZSgpIC0gYS5kYXRlQWRkZWQuZ2V0VGltZSgpKTtcbiAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICBjb25zb2xlLmxvZyhcIkVycm9yIGluIGxvYWQgYmFsbGU6IFwiLCBlcnJvcik7XG5cbiAgICBzaG93VG9hc3Qoe1xuICAgICAgc3R5bGU6IFRvYXN0LlN0eWxlLkZhaWx1cmUsXG4gICAgICB0aXRsZTogXCJGYWlsZWQgdG8gbG9hZCBwaG90b3NcIixcbiAgICAgIG1lc3NhZ2U6IFN0cmluZyhlcnJvciksXG4gICAgfSk7XG4gICAgcmV0dXJuIFtdO1xuICB9XG59XG5cbi8qKlxuICogSW5pdGlhbGl6ZXMgdGhlIHBob3RvIGRpcmVjdG9yeSBhbmQgbG9hZHMgcGhvdG9zXG4gKiBUaGlzIGlzIHRoZSBtYWluIGZ1bmN0aW9uIHRoYXQgc2hvdWxkIGJlIGNhbGxlZCBmcm9tIGNvbXBvbmVudHNcbiAqL1xuZXhwb3J0IGFzeW5jIGZ1bmN0aW9uIGluaXRpYWxpemVBbmRMb2FkUGhvdG9zKCk6IFByb21pc2U8UGhvdG9bXT4ge1xuICBhd2FpdCBlbnN1cmVEaXJlY3RvcnlFeGlzdHMoKTtcblxuICBjb25zdCBtZXRhZGF0YSA9IGF3YWl0IHJlYWRQaG90b01ldGFkYXRhKCk7XG4gIGNvbnN0IHBob3RvcyA9IGF3YWl0IGxvYWRQaG90b3NGcm9tRGlzaygpO1xuXG4gIGNvbnN0IG1ldGEgPSBwaG90b3MubWFwKChwaG90bykgPT4ge1xuICAgIGNvbnN0IHBob3RvTWV0YWRhdGEgPSBtZXRhZGF0YVtwaG90by5uYW1lXSB8fCB7fTtcbiAgICByZXR1cm4ge1xuICAgICAgLi4ucGhvdG8sXG4gICAgICAuLi5waG90b01ldGFkYXRhLFxuICAgIH07XG4gIH0pO1xuXG4gIC8vIGNvbnN0IG1ldGFQaG90b3MgPSBhd2FpdCBzYXZlUGhvdG9NZXRhZGF0YShQSE9UT19ESVIsIG1ldGEpO1xuXG4gIC8vIEFwcGx5IG1ldGFkYXRhIHRvIHBob3Rvc1xuICByZXR1cm4gbWV0YTtcbn1cblxuLyoqXG4gKiBPcGVucyB0aGUgcGhvdG8gY29sbGVjdGlvbiBmb2xkZXIgaW4gRmluZGVyXG4gKi9cbmV4cG9ydCBmdW5jdGlvbiBvcGVuQ29sbGVjdGlvbkZvbGRlcigpIHtcbiAgc2hvd0luRmluZGVyKFBIT1RPX0RJUik7XG59XG4iLCAiaW1wb3J0IHsgcHJvbWlzZXMgYXMgZnMgfSBmcm9tIFwiZnNcIjtcbmltcG9ydCBwYXRoIGZyb20gXCJwYXRoXCI7XG5pbXBvcnQgeyBzaG93VG9hc3QsIFRvYXN0IH0gZnJvbSBcIkByYXljYXN0L2FwaVwiO1xuaW1wb3J0IHsgUEhPVE9fRElSIH0gZnJvbSBcIi4vbG9hZFBob3Rvc1wiO1xuaW1wb3J0IHsgUGhvdG8sIFBob3RvTWV0YWRhdGEgfSBmcm9tIFwiLi90eXBlc1wiO1xuXG4vKipcbiAqIFJlYWRzIHBob3RvIG1ldGFkYXRhIGZyb20gdGhlIG1ldGFkYXRhIGZpbGVcbiAqIEByZXR1cm5zIE9iamVjdCBjb250YWluaW5nIG1ldGFkYXRhIGZvciBhbGwgcGhvdG9zXG4gKi9cbmV4cG9ydCBhc3luYyBmdW5jdGlvbiByZWFkUGhvdG9NZXRhZGF0YSgpOiBQcm9taXNlPFJlY29yZDxzdHJpbmcsIFBob3RvTWV0YWRhdGE+PiB7XG4gIGNvbnN0IGRpciA9IHBhdGguam9pbihQSE9UT19ESVIsIFwibWV0YWRhdGEuanNvblwiKTtcbiAgdHJ5IHtcbiAgICBjb25zdCBkYXRhID0gYXdhaXQgZnMucmVhZEZpbGUoZGlyKTtcblxuICAgIHJldHVybiBKU09OLnBhcnNlKGRhdGEudG9TdHJpbmcoKSk7XG4gIH0gY2F0Y2ggKGVycm9yKSB7XG4gICAgLy8gSWYgZmlsZSBkb2Vzbid0IGV4aXN0LCBjcmVhdGUgaXQgd2l0aCBlbXB0eSBtZXRhZGF0YVxuICAgIGlmICgoZXJyb3IgYXMgTm9kZUpTLkVycm5vRXhjZXB0aW9uKS5jb2RlID09PSBcIkVOT0VOVFwiKSB7XG4gICAgICBhd2FpdCBmcy53cml0ZUZpbGUoZGlyLCBKU09OLnN0cmluZ2lmeSh7fSksIFwidXRmLThcIik7XG4gICAgICByZXR1cm4ge307XG4gICAgfVxuICAgIGNvbnNvbGUuZXJyb3IoXCJFcnJvciByZWFkaW5nIG1ldGFkYXRhOlwiLCBlcnJvcik7XG4gICAgcmV0dXJuIHt9O1xuICB9XG59XG5cbi8qKlxuICogU2F2ZSBtZXRhZGF0YSBmb3IgYSBzcGVjaWZpYyBwaG90b1xuICovXG5cbmV4cG9ydCBhc3luYyBmdW5jdGlvbiBzYXZlUGhvdG9NZXRhZGF0YShmaWxlbmFtZTogc3RyaW5nLCBtZXRhZGF0YTogUGhvdG9NZXRhZGF0YSk6IFByb21pc2U8dm9pZD4ge1xuICBjb25zdCBkaXIgPSBwYXRoLmpvaW4oUEhPVE9fRElSLCBcIm1ldGFkYXRhLmpzb25cIik7XG4gIGNvbnNvbGUubG9nKFBIT1RPX0RJUik7XG4gIHRyeSB7XG4gICAgLy8gUmVhZCBleGlzdGluZyBtZXRhZGF0YVxuICAgIGNvbnN0IGN1cnJlbnRNZXRhZGF0YSA9IGF3YWl0IHJlYWRQaG90b01ldGFkYXRhKCk7XG5cbiAgICAvLyBVcGRhdGUgbWV0YWRhdGEgZm9yIHRoZSBzcGVjaWZpYyBmaWxlXG4gICAgY3VycmVudE1ldGFkYXRhW2ZpbGVuYW1lXSA9IHtcbiAgICAgIC4uLmN1cnJlbnRNZXRhZGF0YVtmaWxlbmFtZV0sXG4gICAgICAuLi5tZXRhZGF0YSxcbiAgICB9O1xuXG4gICAgLy8gV3JpdGUgYmFjayB0byBmaWxlXG4gICAgYXdhaXQgZnMud3JpdGVGaWxlKGRpciwgSlNPTi5zdHJpbmdpZnkoY3VycmVudE1ldGFkYXRhLCBudWxsLCAyKSk7XG4gIH0gY2F0Y2ggKGVycm9yKSB7XG4gICAgc2hvd1RvYXN0KHtcbiAgICAgIHN0eWxlOiBUb2FzdC5TdHlsZS5GYWlsdXJlLFxuICAgICAgdGl0bGU6IFwiRmFpbGVkIHRvIHNhdmUgcGhvdG8gbWV0YWRhdGFcIixcbiAgICAgIG1lc3NhZ2U6IFN0cmluZyhlcnJvciksXG4gICAgfSk7XG4gIH1cbn1cblxuLyoqXG4gKiBVcGRhdGVzIG1ldGFkYXRhIGZvciBhIHNwZWNpZmljIHBob3RvXG4gKiBAcGFyYW0gcGhvdG9OYW1lIFRoZSBmaWxlbmFtZSBvZiB0aGUgcGhvdG9cbiAqIEBwYXJhbSBtZXRhZGF0YSBUaGUgbWV0YWRhdGEgdG8gc2F2ZVxuICovXG5leHBvcnQgYXN5bmMgZnVuY3Rpb24gdXBkYXRlUGhvdG9NZXRhZGF0YShwaG90b05hbWU6IHN0cmluZywgbWV0YWRhdGE6IFBhcnRpYWw8UGhvdG9NZXRhZGF0YT4pOiBQcm9taXNlPHZvaWQ+IHtcbiAgY29uc3QgZGlyID0gcGF0aC5qb2luKFBIT1RPX0RJUiwgXCJtZXRhZGF0YS5qc29uXCIpO1xuXG4gIHRyeSB7XG4gICAgY29uc3QgZXhpc3RpbmdNZXRhZGF0YSA9IGF3YWl0IHJlYWRQaG90b01ldGFkYXRhKCk7XG4gICAgZXhpc3RpbmdNZXRhZGF0YVtwaG90b05hbWVdID0ge1xuICAgICAgLi4uZXhpc3RpbmdNZXRhZGF0YVtwaG90b05hbWVdLFxuICAgICAgLi4ubWV0YWRhdGEsXG4gICAgfTtcbiAgICBhd2FpdCBmcy53cml0ZUZpbGUoZGlyLCBKU09OLnN0cmluZ2lmeShleGlzdGluZ01ldGFkYXRhLCBudWxsLCAyKSwgXCJ1dGYtOFwiKTtcbiAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICBjb25zb2xlLmVycm9yKFwiRXJyb3IgdXBkYXRpbmcgbWV0YWRhdGE6XCIsIGVycm9yKTtcbiAgICB0aHJvdyBlcnJvcjtcbiAgfVxufVxuXG4vKipcbiAqIERlbGV0ZXMgbWV0YWRhdGEgZm9yIGEgc3BlY2lmaWMgcGhvdG9cbiAqIEBwYXJhbSBwaG90b05hbWUgVGhlIGZpbGVuYW1lIG9mIHRoZSBwaG90byB0byBkZWxldGUgbWV0YWRhdGEgZm9yXG4gKi9cbmV4cG9ydCBhc3luYyBmdW5jdGlvbiBkZWxldGVQaG90b01ldGFkYXRhKHBob3RvTmFtZTogc3RyaW5nKTogUHJvbWlzZTx2b2lkPiB7XG4gIGNvbnN0IGRpciA9IHBhdGguam9pbihQSE9UT19ESVIsIFwibWV0YWRhdGEuanNvblwiKTtcblxuICB0cnkge1xuICAgIGNvbnN0IGV4aXN0aW5nTWV0YWRhdGEgPSBhd2FpdCByZWFkUGhvdG9NZXRhZGF0YSgpO1xuICAgIGlmIChleGlzdGluZ01ldGFkYXRhW3Bob3RvTmFtZV0pIHtcbiAgICAgIGRlbGV0ZSBleGlzdGluZ01ldGFkYXRhW3Bob3RvTmFtZV07XG4gICAgICBhd2FpdCBmcy53cml0ZUZpbGUoZGlyLCBKU09OLnN0cmluZ2lmeShleGlzdGluZ01ldGFkYXRhLCBudWxsLCAyKSwgXCJ1dGYtOFwiKTtcbiAgICB9XG4gIH0gY2F0Y2ggKGVycm9yKSB7XG4gICAgY29uc29sZS5lcnJvcihcIkVycm9yIGRlbGV0aW5nIG1ldGFkYXRhOlwiLCBlcnJvcik7XG4gICAgdGhyb3cgZXJyb3I7XG4gIH1cbn1cblxuLyoqXG4gKiBHZXQgbWV0YWRhdGEgZm9yIGEgc3BlY2lmaWMgcGhvdG9cbiAqL1xuZXhwb3J0IGFzeW5jIGZ1bmN0aW9uIGdldFBob3RvTWV0YWRhdGEoZmlsZW5hbWU6IHN0cmluZyk6IFByb21pc2U8UGhvdG9NZXRhZGF0YSB8IHVuZGVmaW5lZD4ge1xuICBjb25zdCBtZXRhZGF0YSA9IGF3YWl0IHJlYWRQaG90b01ldGFkYXRhKCk7XG4gIHJldHVybiBtZXRhZGF0YVtmaWxlbmFtZV07XG59XG5cbi8qKlxuICogR2V0IGFsbCBjYXRlZ29yaWVzIGZyb20gbWV0YWRhdGFcbiAqL1xuZXhwb3J0IGFzeW5jIGZ1bmN0aW9uIGdldEFsbENhdGVnb3JpZXMoKTogUHJvbWlzZTxzdHJpbmdbXT4ge1xuICBjb25zdCBtZXRhZGF0YSA9IGF3YWl0IHJlYWRQaG90b01ldGFkYXRhKCk7XG4gIGNvbnN0IGNhdGVnb3JpZXMgPSBuZXcgU2V0PHN0cmluZz4oKTtcblxuICBPYmplY3QudmFsdWVzKG1ldGFkYXRhKS5mb3JFYWNoKChwaG90bykgPT4ge1xuICAgIGlmIChwaG90by5jYXRlZ29yeSkge1xuICAgICAgY2F0ZWdvcmllcy5hZGQocGhvdG8uY2F0ZWdvcnkpO1xuICAgIH1cbiAgfSk7XG5cbiAgcmV0dXJuIEFycmF5LmZyb20oY2F0ZWdvcmllcykuc29ydCgpO1xufVxuXG4vKipcbiAqIE1lcmdlIGZpbGUgc3lzdGVtIHBob3RvIGRhdGEgd2l0aCBzdG9yZWQgbWV0YWRhdGFcbiAqIFRoaXMgaGVscHMgZW5zdXJlIHdlIGhhdmUgYSBjb21wbGV0ZSBQaG90byBvYmplY3RcbiAqL1xuZXhwb3J0IGFzeW5jIGZ1bmN0aW9uIG1lcmdlUGhvdG9XaXRoTWV0YWRhdGEocGhvdG9EYXRhOiBQYXJ0aWFsPFBob3RvPiwgZmlsZW5hbWU6IHN0cmluZyk6IFByb21pc2U8UGhvdG8+IHtcbiAgY29uc3QgbWV0YWRhdGEgPSAoYXdhaXQgZ2V0UGhvdG9NZXRhZGF0YShmaWxlbmFtZSkpIHx8IHt9O1xuXG4gIHJldHVybiB7XG4gICAgLi4ucGhvdG9EYXRhLFxuICAgIC4uLm1ldGFkYXRhLFxuICB9IGFzIFBob3RvO1xufVxuXG4vKipcbiAqIEluaXRpYWxpemUgbWV0YWRhdGEgZmlsZSBpZiBpdCBkb2Vzbid0IGV4aXN0XG4gKi9cbmV4cG9ydCBhc3luYyBmdW5jdGlvbiBpbml0aWFsaXplTWV0YWRhdGFGaWxlKCk6IFByb21pc2U8dm9pZD4ge1xuICBjb25zdCBkaXIgPSBwYXRoLmpvaW4oUEhPVE9fRElSLCBcIm1ldGFkYXRhLmpzb25cIik7XG5cbiAgdHJ5IHtcbiAgICBhd2FpdCBmcy5hY2Nlc3MoZGlyKTtcbiAgICAvLyBGaWxlIGV4aXN0cywgbm8gbmVlZCB0byBjcmVhdGUgaXRcbiAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICAvLyBGaWxlIGRvZXNuJ3QgZXhpc3QsIGNyZWF0ZSBpdCB3aXRoIGVtcHR5IG9iamVjdFxuICAgIGF3YWl0IGZzLndyaXRlRmlsZShkaXIsIEpTT04uc3RyaW5naWZ5KHt9LCBudWxsLCAyKSk7XG4gICAgY29uc29sZS5sb2coXCJDcmVhdGVkIG5ldyBtZXRhZGF0YSBmaWxlXCIpO1xuICB9XG59XG4iLCAiaW1wb3J0IHsgcHJvbWlzZXMgYXMgZnMgfSBmcm9tIFwiZnNcIjtcbmltcG9ydCB7IHNob3dUb2FzdCwgVG9hc3QsIGNvbmZpcm1BbGVydCwgQWxlcnQgfSBmcm9tIFwiQHJheWNhc3QvYXBpXCI7XG5cbi8qKlxuICogUmVtb3ZlcyBhIHBob3RvIGZyb20gZGlza1xuICogQHBhcmFtIHBob3RvUGF0aCBQYXRoIHRvIHRoZSBwaG90byBmaWxlXG4gKiBAcmV0dXJucyBQcm9taXNlPGJvb2xlYW4+IGluZGljYXRpbmcgc3VjY2VzcyBvciBmYWlsdXJlXG4gKi9cbmV4cG9ydCBhc3luYyBmdW5jdGlvbiBkZWxldGVQaG90byhwaG90b1BhdGg6IHN0cmluZyk6IFByb21pc2U8Ym9vbGVhbj4ge1xuICB0cnkge1xuICAgIGF3YWl0IGZzLnVubGluayhwaG90b1BhdGgpO1xuICAgIHJldHVybiB0cnVlO1xuICB9IGNhdGNoIChlcnJvcikge1xuICAgIGF3YWl0IHNob3dUb2FzdCh7XG4gICAgICBzdHlsZTogVG9hc3QuU3R5bGUuRmFpbHVyZSxcbiAgICAgIHRpdGxlOiBcIkZhaWxlZCB0byByZW1vdmUgcGhvdG9cIixcbiAgICAgIG1lc3NhZ2U6IFN0cmluZyhlcnJvciksXG4gICAgfSk7XG4gICAgcmV0dXJuIGZhbHNlO1xuICB9XG59XG5cbi8qKlxuICogSGFuZGxlcyB0aGUgY29uZmlybWF0aW9uIGFuZCBkZWxldGlvbiBvZiBhIHBob3RvXG4gKiBAcGFyYW0gcGhvdG9QYXRoIFBhdGggdG8gdGhlIHBob3RvIGZpbGVcbiAqIEByZXR1cm5zIFByb21pc2U8Ym9vbGVhbj4gaW5kaWNhdGluZyBpZiB0aGUgcGhvdG8gd2FzIGRlbGV0ZWRcbiAqL1xuZXhwb3J0IGFzeW5jIGZ1bmN0aW9uIGNvbmZpcm1BbmREZWxldGVQaG90byhwaG90b1BhdGg6IHN0cmluZyk6IFByb21pc2U8Ym9vbGVhbj4ge1xuICBjb25zdCBjb25maXJtZWQgPSBhd2FpdCBjb25maXJtQWxlcnQoe1xuICAgIHRpdGxlOiBcIkRlbGV0ZSBQaG90b1wiLFxuICAgIG1lc3NhZ2U6IFwiQXJlIHlvdSBzdXJlIHlvdSB3YW50IHRvIGRlbGV0ZSB0aGlzIHBob3RvIGZyb20geW91ciBjb2xsZWN0aW9uP1wiLFxuICAgIHByaW1hcnlBY3Rpb246IHtcbiAgICAgIHRpdGxlOiBcIkRlbGV0ZVwiLFxuICAgICAgc3R5bGU6IEFsZXJ0LkFjdGlvblN0eWxlLkRlc3RydWN0aXZlLFxuICAgIH0sXG4gIH0pO1xuXG4gIGlmIChjb25maXJtZWQpIHtcbiAgICBjb25zdCBzdWNjZXNzID0gYXdhaXQgZGVsZXRlUGhvdG8ocGhvdG9QYXRoKTtcblxuICAgIGlmIChzdWNjZXNzKSB7XG4gICAgICBhd2FpdCBzaG93VG9hc3Qoe1xuICAgICAgICBzdHlsZTogVG9hc3QuU3R5bGUuU3VjY2VzcyxcbiAgICAgICAgdGl0bGU6IFwiUGhvdG8gcmVtb3ZlZCBmcm9tIGNvbGxlY3Rpb25cIixcbiAgICAgIH0pO1xuICAgIH1cblxuICAgIHJldHVybiBzdWNjZXNzO1xuICB9XG5cbiAgcmV0dXJuIGZhbHNlO1xufVxuIl0sCiAgIm1hcHBpbmdzIjogIjs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0FBQUE7QUFBQTtBQUFBO0FBQUE7QUFBQTtBQUFBLG1CQUFvQztBQUNwQyxJQUFBQSxjQUF3RDs7O0FDRHhELElBQUFDLGFBQStCO0FBQy9CLElBQUFDLGVBQWlCO0FBQ2pCLElBQUFDLGNBQTREOzs7QUNGNUQsZ0JBQStCO0FBQy9CLGtCQUFpQjtBQUNqQixpQkFBaUM7QUFRakMsZUFBc0Isb0JBQTREO0FBQ2hGLFFBQU0sTUFBTSxZQUFBQyxRQUFLLEtBQUssV0FBVyxlQUFlO0FBQ2hELE1BQUk7QUFDRixVQUFNLE9BQU8sTUFBTSxVQUFBQyxTQUFHLFNBQVMsR0FBRztBQUVsQyxXQUFPLEtBQUssTUFBTSxLQUFLLFNBQVMsQ0FBQztBQUFBLEVBQ25DLFNBQVMsT0FBTztBQUVkLFFBQUssTUFBZ0MsU0FBUyxVQUFVO0FBQ3RELFlBQU0sVUFBQUEsU0FBRyxVQUFVLEtBQUssS0FBSyxVQUFVLENBQUMsQ0FBQyxHQUFHLE9BQU87QUFDbkQsYUFBTyxDQUFDO0FBQUEsSUFDVjtBQUNBLFlBQVEsTUFBTSwyQkFBMkIsS0FBSztBQUM5QyxXQUFPLENBQUM7QUFBQSxFQUNWO0FBQ0Y7OztBRG5CTyxJQUFNLFlBQVksYUFBQUMsUUFBSyxLQUFLLHdCQUFZLGFBQWEsaUJBQWlCO0FBSzdFLGVBQXNCLHdCQUF1QztBQUMzRCxNQUFJO0FBQ0YsVUFBTSxRQUFRLE1BQU0sV0FBQUMsU0FBRyxLQUFLLFNBQVM7QUFDckMsUUFBSSxDQUFDLE1BQU0sWUFBWSxHQUFHO0FBQ3hCLFlBQU0sSUFBSSxNQUFNLGlCQUFpQjtBQUFBLElBQ25DO0FBQUEsRUFDRixTQUFTLE9BQU87QUFFZCxVQUFNLFdBQUFBLFNBQUcsTUFBTSxXQUFXLEVBQUUsV0FBVyxLQUFLLENBQUM7QUFBQSxFQUMvQztB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QUFHO0FBQUEsYUFDNUY7QUFBQTtBQUFBLE1BRUosSUFFQSxPQUFPLElBQUksQ0FBQyxVQUNWO0FBQUEsUUFBQyxpQkFBSztBQUFBLFFBQUw7QUFBQSxVQUVDLFNBQVMsTUFBTTtBQUFBLFVBQ2YsT0FBTyxNQUFNO0FBQUEsVUFDYixVQUFVLElBQUksS0FBSyxNQUFNLFNBQVMsRUFBRSxtQkFBbUI7QUFBQSxVQUN2RCxTQUNFLDZDQUFDLDJCQUNDO0FBQUEsd0RBQUMsbUJBQU8sVUFBUCxFQUFnQixNQUFNLE1BQU0sTUFBTSxPQUFNLGFBQVk7QUFBQSxZQUNyRCw0Q0FBQyxzQkFBTyxPQUFNLGtCQUFpQixVQUFVLFVBQU0sMEJBQWEsTUFBTSxJQUFJLEdBQUc7QUFBQSxZQUN6RSw0Q0FBQyxtQkFBTyxpQkFBUCxFQUF1QixPQUFNLGFBQVksU0FBUyxNQUFNLE1BQU07QUFBQSxZQUMvRDtBQUFBLGNBQUMsbUJBQU87QUFBQSxjQUFQO0FBQUEsZ0JBQ0MsT0FBTTtBQUFBLGdCQUNOLFNBQVMsRUFBRSxNQUFNLE1BQU0sS0FBSztBQUFBLGdCQUM1QixVQUFVLEVBQUUsV0FBVyxDQUFDLEtBQUssR0FBRyxLQUFLLElBQUk7QUFBQTtBQUFBLFlBQzNDO0FBQUEsWUFDQSw0Q0FBQyxzQkFBTyxPQUFNLDBCQUF5QixVQUFVLHNCQUFzQjtBQUFBLFlBQ3ZFO0FBQUEsY0FBQztBQUFBO0FBQUEsZ0JBQ0MsT0FBTTtBQUFBLGdCQUNOLE9BQU8sbUJBQU8sTUFBTTtBQUFBLGdCQUNwQixVQUFVLE1BQU0sa0JBQWtCLE1BQU0sSUFBSTtBQUFBLGdCQUM1QyxVQUFVLEVBQUUsV0FBVyxDQUFDLEtBQUssR0FBRyxLQUFLLFlBQVk7QUFBQTtBQUFBLFlBQ25EO0FBQUEsYUFDRjtBQUFBO0FBQUEsUUFyQkcsTUFBTTtBQUFBLE1BdUJiLENBQ0Q7QUFBQTtBQUFBLEVBRUw7QUFFSjsiLAogICJuYW1lcyI6IFsiaW1wb3J0X2FwaSIsICJpbXBvcnRfZnMiLCAiaW1wb3J0X3BhdGgiLCAiaW1wb3J0X2FwaSIsICJwYXRoIiwgImZzIiwgInBhdGgiLCAiZnMiLCAiaW1wb3J0X2ZzIiwgImltcG9ydF9hcGkiLCAiZnMiXQp9Cg==
