export enum ListStatus {
    OK = "OK",
    EMPTY = "EMPTY",
    ERROR = "ERROR",
}

export type ListState = {
    status: ListStatus;
    message: string;   // 화면에 그대로 띄울 문장. 정상 목록일 때는 빈 문자열.
};
