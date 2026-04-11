/// Type declarations for node-iap

declare module 'node-iap' {
  export interface AppleIAPConfiguration {
    secret: string;
    environment?: string[];
    excludeOldTransactions?: boolean;
  }

  export interface GoogleIAPConfiguration {
    type: string;
    project_id: string;
    private_key_id: string;
    private_key: string;
    client_email: string;
    client_id: string;
    auth_uri: string;
    token_uri: string;
    auth_provider_x509_cert_url: string;
    client_x509_cert_url: string;
  }

  export interface AppleReceipt {
    data: string;
    productId: string;
  }

  export interface GoogleReceipt {
    data: string;
    signature: string;
  }

  export interface ValidationResult {
    receipt?: {
      [key: string]: any;
    };
    [key: string]: any;
  }

  export function verifyPayment(
    platform: 'apple' | 'google',
    receipt: AppleReceipt | GoogleReceipt,
    config: AppleIAPConfiguration | GoogleIAPConfiguration | null,
  ): Promise<ValidationResult>;
}
