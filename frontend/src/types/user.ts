export type User = {
    id: number;
    name: string;
    email: string;
    createdAt: string;
    lastLoginAt: string | null;   // 한 번도 로그인하지 않은 사용자는 null로 내려온다.
};
