import {StrictMode} from "react";
import {createRoot} from "react-dom/client";
import User from "./pages/user/User";

const rootElement: HTMLElement | null = document.getElementById("root");
if (rootElement === null) {
    throw new Error("index.html 에 #root 가 없습니다.");
}

createRoot(rootElement).render(
    <StrictMode>
        <User />
    </StrictMode>,
);
